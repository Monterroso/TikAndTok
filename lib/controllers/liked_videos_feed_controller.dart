import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';
import 'video_collection_manager.dart';
import 'video_feed_controller.dart';

class LikedVideosFeedController extends VideoFeedController {
  final FirestoreService _firestoreService;
  final String _userId;
  final VideoCollectionManager _collectionManager;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  Video? _currentVideo;

  LikedVideosFeedController({
    required String userId,
    required VideoCollectionManager collectionManager,
    FirestoreService? firestoreService,
  }) : _userId = userId,
       _collectionManager = collectionManager,
       _firestoreService = firestoreService ?? FirestoreService(),
       super(
         feedTitle: 'Liked Videos',
         showBackButton: true,
         collectionManager: collectionManager,
       );

  Video? get currentVideo => _currentVideo;

  @override
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize) async {
    if (_isLoading || !_hasMore) return [];

    try {
      _isLoading = true;
      notifyListeners();

      // Get liked videos from cache
      final likedVideoIds = _collectionManager.getLikedVideoIds(_userId);
      
      if (likedVideoIds.isEmpty) {
        _hasMore = false;
        return [];
      }

      List<Video> videos;
      
      // If we don't have a lastDocument and lastVideoId is provided,
      // we need to fetch the document first
      if (_lastDocument == null && lastVideoId != null) {
        _lastDocument = await FirebaseFirestore.instance
            .collection('videos')
            .doc(lastVideoId)
            .get();
      }

      // Get the next batch of videos that are in the likedVideoIds set
      if (_lastDocument != null) {
        videos = await _firestoreService.getNextFilteredVideos(
          lastVideo: _lastDocument!,
          limit: pageSize,
          filterIds: likedVideoIds,
        );
      } else {
        // If no last document, start from the beginning
        videos = await _firestoreService.getVideosByIds(
          videoIds: likedVideoIds.take(pageSize).toList(),
        );
      }

      // Store the last document for next pagination if we got any videos
      if (videos.isNotEmpty) {
        _lastDocument = await FirebaseFirestore.instance
            .collection('videos')
            .doc(videos.last.id)
            .get();
      }

      // Update hasMore based on whether we got a full page
      _hasMore = videos.length >= pageSize;
      _error = null;

      return videos;
    } catch (e) {
      _error = 'Failed to load liked videos: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> onVideoInteraction(Video video) async {
    _currentVideo = video;
    notifyListeners();
  }

  @override
  bool shouldKeepVideo(Video video) {
    // Only keep videos that are still liked
    return _collectionManager.isVideoLiked(video.id);
  }

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
    // Reset pagination state
    _lastDocument = null;
    _hasMore = true;
    _currentVideo = null;
    return getNextPage(null, 10);
  }
} 