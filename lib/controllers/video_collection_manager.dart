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
  bool _isLoadingFollowing = false;
  
  // Video collections
  List<Video> _likedVideos = [];
  List<Video> _savedVideos = [];
  List<Video> _followingVideos = [];
  
  // Getters
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingLiked => _isLoadingLiked;
  bool get isLoadingSaved => _isLoadingSaved;
  bool get isLoadingFollowing => _isLoadingFollowing;
  List<Video> get likedVideos => List.unmodifiable(_likedVideos);
  List<Video> get savedVideos => List.unmodifiable(_savedVideos);
  List<Video> get followingVideos => List.unmodifiable(_followingVideos);

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

  /// Gets a video state from cache only (synchronous)
  VideoState? getCachedVideoState(String videoId) {
    return _cache.get(videoId);
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
      // Get current state
      final currentState = await getVideoState(videoId);
      
      // If no state exists, fetch the video first
      Video? video = currentState?.videoData;
      if (video == null) {
        final doc = await _firestoreService.getVideoDocument(videoId);
        if (doc.exists) {
          video = Video.fromFirestore(doc);
        } else {
          return;
        }
      }

      // Calculate new state
      final isCurrentlyLiked = video.isLikedByUser(userId);
      final newLikedBy = Set<String>.from(video.likedBy);
      if (isCurrentlyLiked) {
        newLikedBy.remove(userId);
      } else {
        newLikedBy.add(userId);
      }

      // Create optimistically updated video
      final updatedVideo = Video(
        id: video.id,
        url: video.url,
        userId: video.userId,
        title: video.title,
        description: video.description,
        likes: video.likes + (isCurrentlyLiked ? -1 : 1),
        comments: video.comments,
        createdAt: video.createdAt,
        metadata: video.metadata,
        likedBy: newLikedBy,
        savedBy: video.savedBy,
      );

      // Update state with optimistic changes immediately
      final newState = VideoState(
        videoId: videoId,
        lastUpdated: DateTime.now(),
        isLiked: !isCurrentlyLiked,
        isSaved: currentState?.isSaved ?? false,
        videoData: updatedVideo,
      );
      _cache.put(newState);
      notifyListeners();

      // Update storage in background
      _storage.saveVideoState(newState);

      // Perform the actual update
      await _firestoreService.toggleLike(
        videoId: videoId,
        userId: userId,
      );

      // Refresh liked videos list in background
      fetchLikedVideos(userId);
    } catch (e) {
      // Revert optimistic update on error
      final currentState = await getVideoState(videoId);
      final video = currentState?.videoData;
      if (video != null) {
        final isCurrentlyLiked = !video.isLikedByUser(userId);
        final newLikedBy = Set<String>.from(video.likedBy);
        if (isCurrentlyLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        final revertedVideo = Video(
          id: video.id,
          url: video.url,
          userId: video.userId,
          title: video.title,
          description: video.description,
          likes: video.likes + (isCurrentlyLiked ? -1 : 1),
          comments: video.comments,
          createdAt: video.createdAt,
          metadata: video.metadata,
          likedBy: newLikedBy,
          savedBy: video.savedBy,
        );

        final revertedState = VideoState(
          videoId: videoId,
          lastUpdated: DateTime.now(),
          isLiked: !isCurrentlyLiked,
          isSaved: currentState?.isSaved ?? false,
          videoData: revertedVideo,
          error: 'Failed to toggle like: $e',
        );
        _cache.put(revertedState);
        notifyListeners();

        // Update storage in background
        _storage.saveVideoState(revertedState);
      }
    }
  }

  /// Toggles the saved status of a video
  Future<void> toggleSaveVideo(String videoId, String userId) async {
    try {
      // Get current state
      final currentState = await getVideoState(videoId);
      
      // If no state exists, fetch the video first
      Video? video = currentState?.videoData;
      if (video == null) {
        final doc = await _firestoreService.getVideoDocument(videoId);
        if (doc.exists) {
          video = Video.fromFirestore(doc);
        } else {
          return;
        }
      }

      // Calculate new state
      final isCurrentlySaved = video.isSavedByUser(userId);
      final newSavedBy = Set<String>.from(video.savedBy);
      if (isCurrentlySaved) {
        newSavedBy.remove(userId);
      } else {
        newSavedBy.add(userId);
      }

      // Create optimistically updated video
      final updatedVideo = Video(
        id: video.id,
        url: video.url,
        userId: video.userId,
        title: video.title,
        description: video.description,
        likes: video.likes,
        comments: video.comments,
        createdAt: video.createdAt,
        metadata: video.metadata,
        likedBy: video.likedBy,
        savedBy: newSavedBy,
      );

      // Update state with optimistic changes immediately
      final newState = VideoState(
        videoId: videoId,
        lastUpdated: DateTime.now(),
        isLiked: currentState?.isLiked ?? false,
        isSaved: !isCurrentlySaved,
        videoData: updatedVideo,
      );
      _cache.put(newState);
      notifyListeners();

      // Update storage in background
      _storage.saveVideoState(newState);

      // Perform the actual update
      await _firestoreService.toggleSave(
        videoId: videoId,
        userId: userId,
      );

      // Refresh saved videos list in background
      fetchSavedVideos(userId);
    } catch (e) {
      // Revert optimistic update on error
      final currentState = await getVideoState(videoId);
      final video = currentState?.videoData;
      if (video != null) {
        final isCurrentlySaved = !video.isSavedByUser(userId);
        final newSavedBy = Set<String>.from(video.savedBy);
        if (isCurrentlySaved) {
          newSavedBy.remove(userId);
        } else {
          newSavedBy.add(userId);
        }

        final revertedVideo = Video(
          id: video.id,
          url: video.url,
          userId: video.userId,
          title: video.title,
          description: video.description,
          likes: video.likes,
          comments: video.comments,
          createdAt: video.createdAt,
          metadata: video.metadata,
          likedBy: video.likedBy,
          savedBy: newSavedBy,
        );

        final revertedState = VideoState(
          videoId: videoId,
          lastUpdated: DateTime.now(),
          isLiked: currentState?.isLiked ?? false,
          isSaved: !isCurrentlySaved,
          videoData: revertedVideo,
          error: 'Failed to toggle save: $e',
        );
        _cache.put(revertedState);
        notifyListeners();

        // Update storage in background
        _storage.saveVideoState(revertedState);
      }
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

  /// Fetches following videos for a user
  Future<void> fetchFollowingVideos(String userId) async {
    if (_isLoadingFollowing) return;

    try {
      _isLoadingFollowing = true;
      _error = null;
      notifyListeners();

      final videos = await _firestoreService.getFollowingVideos(userId);
      _followingVideos = videos;
      
      // Update video states
      for (final video in videos) {
        _cache.put(VideoState(
          videoId: video.id,
          lastUpdated: DateTime.now(),
          isLiked: video.isLikedByUser(userId),
          isSaved: video.isSavedByUser(userId),
          videoData: video,
        ));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingFollowing = false;
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

  /// Gets the set of liked video IDs for a user
  Set<String> getLikedVideoIds(String userId) {
    final likedIds = <String>{};
    
    // Check cache for liked videos
    for (final state in _cache.values()) {
      if (state.isLiked && state.videoData?.isLikedByUser(userId) == true) {
        likedIds.add(state.videoId);
      }
    }
    
    return likedIds;
  }

  /// Gets the like count for a video
  int getLikeCount(String videoId) {
    final state = getCachedVideoState(videoId);
    return state?.videoData?.likes ?? 0;
  }

  /// Gets the save count for a video
  int getSaveCount(String videoId) {
    final state = getCachedVideoState(videoId);
    return state?.videoData?.savedBy.length ?? 0;
  }

  /// Gets the set of saved video IDs for a user
  Set<String> getSavedVideoIds(String userId) {
    final savedIds = <String>{};
    
    // Check cache for saved videos
    for (final state in _cache.values()) {
      if (state.isSaved && state.videoData?.isSavedByUser(userId) == true) {
        savedIds.add(state.videoId);
      }
    }
    
    return savedIds;
  }

  /// Checks if a video is liked by the current user
  bool isVideoLiked(String videoId) {
    final state = getCachedVideoState(videoId);
    return state?.isLiked ?? false;
  }

  /// Checks if a video is saved by the current user
  bool isVideoSaved(String videoId) {
    final state = getCachedVideoState(videoId);
    return state?.isSaved ?? false;
  }

  /// Toggles the follow status of a user
  Future<void> toggleFollow(String userId, String creatorId) async {
    try {
      await _firestoreService.toggleFollow(
        followerId: userId,
        followedId: creatorId,
      );
      
      // Refresh following videos after toggling follow
      await fetchFollowingVideos(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
} 