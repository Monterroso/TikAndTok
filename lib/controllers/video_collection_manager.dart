import 'package:flutter/foundation.dart';
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
  
  // Error and loading states
  String? _error;
  bool _isLoading = false;
  
  // Getters
  String? get error => _error;
  bool get isLoading => _isLoading;

  VideoCollectionManager({
    FirestoreService? firestoreService,
    VideoStateCache? cache,
    VideoStateStorage? storage,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _cache = cache ?? VideoStateCache(),
       _storage = storage ?? (throw ArgumentError('storage is required'));

  /// Factory constructor to create an instance with all dependencies
  static Future<VideoCollectionManager> create() async {
    final storage = await VideoStateStorage.create();
    return VideoCollectionManager(storage: storage);
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

  /// Gets all liked videos
  Future<List<Video>> getLikedVideos(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final videos = await _firestoreService.getLikedVideos(userId);
      
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

      return videos;
    } catch (e) {
      _error = 'Failed to get liked videos: $e';
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets all saved videos
  Future<List<Video>> getSavedVideos(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final videos = await _firestoreService.getSavedVideos(userId);
      
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

      return videos;
    } catch (e) {
      _error = 'Failed to get saved videos: $e';
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
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
} 