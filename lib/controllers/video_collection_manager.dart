import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';
import '../state/video_state.dart';
import '../state/video_state_cache.dart';
import '../state/video_state_storage.dart';

/// Manages video collections and their states with caching and persistence
class VideoCollectionManager extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final VideoStateCache _cache;
  final VideoStateStorage _storage;
  final String? _currentUserId;
  
  // Error and loading states
  String? _error;
  bool _isLoading = false;
  bool _isLoadingLiked = false;
  bool _isLoadingSaved = false;
  
  // Video collections
  List<Video> _likedVideos = [];
  List<Video> _savedVideos = [];
  
  // Getters
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingLiked => _isLoadingLiked;
  bool get isLoadingSaved => _isLoadingSaved;
  List<Video> get likedVideos => List.unmodifiable(_likedVideos);
  List<Video> get savedVideos => List.unmodifiable(_savedVideos);

  VideoCollectionManager({
    FirestoreService? firestoreService,
    VideoStateCache? cache,
    VideoStateStorage? storage,
    String? currentUserId,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _cache = cache ?? VideoStateCache(),
       _storage = storage ?? (throw ArgumentError('storage is required')),
       _currentUserId = currentUserId;

  /// Factory constructor to create an instance with all dependencies
  static Future<VideoCollectionManager> create() async {
    final storage = await VideoStateStorage.create();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return VideoCollectionManager(
      storage: storage,
      currentUserId: currentUserId,
    );
  }

  /// Initializes the manager by loading persisted states
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      final states = await _storage.loadAllVideoStates();
      for (final state in states) {
        _cache.put(state);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets a video state from cache or storage
  Future<VideoState?> getVideoState(String videoId) async {
    // Try cache first
    var state = _cache.get(videoId);
    if (state != null) return state;

    // Try storage
    state = await _storage.loadVideoState(videoId);
    if (state != null) {
      _cache.put(state);
      return state;
    }

    return null;
  }

  /// Updates video state with optimistic updates
  Future<void> _updateVideoState(String videoId, VideoState Function(VideoState?) update) async {
    try {
      // Get current state or create new one
      final currentState = await getVideoState(videoId) ?? 
          VideoState(videoId: videoId, lastUpdated: DateTime.now());

      // Apply update
      final newState = update(currentState);

      // Optimistically update cache
      _cache.put(newState);
      notifyListeners();

      // Persist to storage
      await _storage.saveVideoState(newState);
    } catch (e) {
      _error = 'Failed to update video state: $e';
      notifyListeners();
    }
  }

  /// Toggles the liked status of a video
  Future<void> toggleLikeVideo(String videoId, String userId) async {
    try {
      await _updateVideoState(videoId, (currentState) {
        final isLiked = !(currentState?.isLiked ?? false);
        return (currentState ?? VideoState(
          videoId: videoId,
          lastUpdated: DateTime.now(),
        )).copyWith(isLiked: isLiked);
      });

      // Perform the actual update
      await _firestoreService.toggleLike(
        videoId: videoId,
        userId: userId,
      );

      // Refresh liked videos list
      await fetchLikedVideos(userId);
    } catch (e) {
      // Revert optimistic update on error
      await _updateVideoState(videoId, (currentState) {
        return currentState!.copyWith(
          isLiked: !currentState.isLiked,
          error: 'Failed to toggle like: $e',
        );
      });
    }
  }

  /// Toggles the saved status of a video
  Future<void> toggleSaveVideo(String videoId, String userId) async {
    try {
      await _updateVideoState(videoId, (currentState) {
        final isSaved = !(currentState?.isSaved ?? false);
        return (currentState ?? VideoState(
          videoId: videoId,
          lastUpdated: DateTime.now(),
        )).copyWith(isSaved: isSaved);
      });

      // Perform the actual update
      await _firestoreService.toggleSave(
        videoId: videoId,
        userId: userId,
      );

      // Refresh saved videos list
      await fetchSavedVideos(userId);
    } catch (e) {
      // Revert optimistic update on error
      await _updateVideoState(videoId, (currentState) {
        return currentState!.copyWith(
          isSaved: !currentState.isSaved,
          error: 'Failed to toggle save: $e',
        );
      });
    }
  }

  /// Fetches liked videos for a user
  Future<void> fetchLikedVideos(String userId) async {
    try {
      _isLoadingLiked = true;
      notifyListeners();

      final videos = await _firestoreService.getLikedVideos(userId);
      _likedVideos = videos;
      
      // Update cache with video states
      for (final video in videos) {
        await _updateVideoState(video.id, (currentState) {
          return (currentState ?? VideoState(
            videoId: video.id,
            lastUpdated: DateTime.now(),
          )).copyWith(
            isLiked: true,
            videoData: video,
          );
        });
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to fetch liked videos: $e';
    } finally {
      _isLoadingLiked = false;
      notifyListeners();
    }
  }

  /// Fetches saved videos for a user
  Future<void> fetchSavedVideos(String userId) async {
    try {
      _isLoadingSaved = true;
      notifyListeners();

      final videos = await _firestoreService.getSavedVideos(userId);
      _savedVideos = videos;
      
      // Update cache with video states
      for (final video in videos) {
        await _updateVideoState(video.id, (currentState) {
          return (currentState ?? VideoState(
            videoId: video.id,
            lastUpdated: DateTime.now(),
          )).copyWith(
            isSaved: true,
            videoData: video,
          );
        });
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to fetch saved videos: $e';
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  /// Cleans up old states and performs maintenance
  Future<void> cleanup() async {
    try {
      await _storage.cleanup(const Duration(days: 7));
      _cache.clearStale();
    } catch (e) {
      _error = 'Failed to cleanup: $e';
      notifyListeners();
    }
  }

  /// Clears any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Gets the like count for a video, including optimistic updates
  int getLikeCount(String videoId) {
    final state = _cache.get(videoId);
    if (state == null) return 0;
    
    final video = state.videoData;
    if (video == null || _currentUserId == null) return video?.likeCount ?? 0;

    final isLikedInCache = likedVideos.any((v) => v.id == videoId);
    final isLikedInVideo = video.isLikedByUser(_currentUserId!);

    // If the states differ, adjust the count accordingly
    if (isLikedInCache != isLikedInVideo) {
      return video.likeCount + (isLikedInCache ? 1 : -1);
    }

    return video.likeCount;
  }

  /// Gets the save count for a video, including optimistic updates
  int getSaveCount(String videoId) {
    final state = _cache.get(videoId);
    if (state == null) return 0;
    
    final video = state.videoData;
    if (video == null || _currentUserId == null) return video?.saveCount ?? 0;

    final isSavedInCache = savedVideos.any((v) => v.id == videoId);
    final isSavedInVideo = video.isSavedByUser(_currentUserId!);

    // If the states differ, adjust the count accordingly
    if (isSavedInCache != isSavedInVideo) {
      return video.saveCount + (isSavedInCache ? 1 : -1);
    }

    return video.saveCount;
  }
} 