import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';

/// Manages the state and operations for video collections (liked and saved videos).
/// Uses ChangeNotifier for state management with Provider.
class VideoCollectionManager extends ChangeNotifier {
  final FirestoreService _firestoreService;
  
  // State variables
  List<Video> _likedVideos = [];
  List<Video> _savedVideos = [];
  bool _isLoadingLiked = false;
  bool _isLoadingSaved = false;
  String? _error;

  // Getters
  List<Video> get likedVideos => List.unmodifiable(_likedVideos);
  List<Video> get savedVideos => List.unmodifiable(_savedVideos);
  bool get isLoadingLiked => _isLoadingLiked;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get error => _error;

  VideoCollectionManager({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  /// Fetches and streams liked videos for a user
  Future<void> fetchLikedVideos(String userId) async {
    try {
      _isLoadingLiked = true;
      _error = null;
      notifyListeners();

      // Subscribe to the stream of liked videos
      _firestoreService.streamLikedVideos(userId: userId).listen(
        (videos) {
          _likedVideos = videos;
          _isLoadingLiked = false;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Failed to fetch liked videos: $e';
          _isLoadingLiked = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to fetch liked videos: $e';
      _isLoadingLiked = false;
      notifyListeners();
    }
  }

  /// Fetches and streams saved videos for a user
  Future<void> fetchSavedVideos(String userId) async {
    try {
      _isLoadingSaved = true;
      _error = null;
      notifyListeners();

      // Subscribe to the stream of saved videos
      _firestoreService.streamSavedVideos(userId: userId).listen(
        (videos) {
          _savedVideos = videos;
          _isLoadingSaved = false;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Failed to fetch saved videos: $e';
          _isLoadingSaved = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to fetch saved videos: $e';
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  /// Toggles the saved status of a video
  Future<void> toggleSaveVideo(String videoId, String userId) async {
    try {
      _error = null;
      // Optimistically update the UI
      final videoIndex = _savedVideos.indexWhere((v) => v.id == videoId);
      final wasAlreadySaved = videoIndex != -1;

      if (wasAlreadySaved) {
        _savedVideos.removeAt(videoIndex);
      } else {
        // If we have the video in liked videos, we can use that data
        final video = _likedVideos.firstWhere(
          (v) => v.id == videoId,
          orElse: () => _savedVideos.firstWhere(
            (v) => v.id == videoId,
            orElse: () => throw 'Video not found',
          ),
        );
        _savedVideos.insert(0, video);
      }
      notifyListeners();

      // Perform the actual update
      await _firestoreService.toggleSave(
        videoId: videoId,
        userId: userId,
      );
    } catch (e) {
      _error = 'Failed to toggle save: $e';
      // Revert the optimistic update
      await fetchSavedVideos(userId);
      notifyListeners();
    }
  }

  /// Toggles the liked status of a video
  Future<void> toggleLikeVideo(String videoId, String userId) async {
    try {
      _error = null;
      // Optimistically update the UI
      final videoIndex = _likedVideos.indexWhere((v) => v.id == videoId);
      final wasAlreadyLiked = videoIndex != -1;

      if (wasAlreadyLiked) {
        _likedVideos.removeAt(videoIndex);
      } else {
        // If we have the video in saved videos, we can use that data
        final video = _savedVideos.firstWhere(
          (v) => v.id == videoId,
          orElse: () => _likedVideos.firstWhere(
            (v) => v.id == videoId,
            orElse: () => throw 'Video not found',
          ),
        );
        _likedVideos.insert(0, video);
      }
      notifyListeners();

      // Perform the actual update
      await _firestoreService.toggleLike(
        videoId: videoId,
        userId: userId,
      );
    } catch (e) {
      _error = 'Failed to toggle like: $e';
      // Revert the optimistic update
      await fetchLikedVideos(userId);
      notifyListeners();
    }
  }

  /// Filters videos by category
  List<Video> filterVideosByCategory(String category, {bool saved = true}) {
    final videos = saved ? _savedVideos : _likedVideos;
    if (category.isEmpty) return videos;
    
    return videos.where((video) {
      final metadata = video.metadata;
      if (metadata == null) return false;
      
      final videoCategory = metadata['category'] as String?;
      return videoCategory == category;
    }).toList();
  }

  /// Searches videos by title or description
  List<Video> searchVideos(String query, {bool saved = true}) {
    final videos = saved ? _savedVideos : _likedVideos;
    if (query.isEmpty) return videos;

    final lowercaseQuery = query.toLowerCase();
    return videos.where((video) {
      return video.title.toLowerCase().contains(lowercaseQuery) ||
             video.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Clears any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 