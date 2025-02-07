import 'package:flutter/foundation.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';
import 'video_feed_controller.dart';
import 'video_collection_manager.dart';

class UserVideosFeedController extends VideoFeedController {
  final String userId;
  final int initialIndex;
  final String username;
  final FirestoreService _firestoreService;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  Video? _lastVideo;

  UserVideosFeedController({
    required this.userId,
    required this.initialIndex,
    required this.username,
    required VideoCollectionManager collectionManager,
    FirestoreService? firestoreService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        super(
          feedTitle: '@$username\'s Videos',
          showBackButton: true,
          collectionManager: collectionManager,
        );

  @override
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize) async {
    if (_isLoading || !_hasMore) return [];

    try {
      _isLoading = true;
      notifyListeners();

      final videos = await _firestoreService.getUserVideos(
        userId: userId,
        startAfter: _lastVideo != null ? 
          await _firestoreService.getVideoDocument(_lastVideo!.id) : null,
        limit: pageSize,
      );

      if (videos.isNotEmpty) {
        _lastVideo = videos.last;
      }

      _hasMore = videos.length >= pageSize;
      _error = null;

      return videos;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> onVideoInteraction(Video video) async {
    // No special handling needed for user videos feed
  }

  @override
  bool shouldKeepVideo(Video video) => true;

  @override
  bool get hasMoreVideos => _hasMore;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  Future<List<Video>> getInitialVideos() async {
    _lastVideo = null;
    _hasMore = true;
    return getNextPage(null, 10);
  }
} 