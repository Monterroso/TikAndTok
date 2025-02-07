import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';
import 'video_feed_controller.dart';
import 'video_collection_manager.dart';

class HomeFeedController extends VideoFeedController {
  final FirestoreService _firestoreService;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  HomeFeedController({
    required VideoCollectionManager collectionManager,
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       super(
         feedTitle: 'For You',
         showBackButton: false,
         collectionManager: collectionManager,
       );

  @override
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize) async {
    if (_isLoading || !_hasMore) return [];

    try {
      _isLoading = true;
      notifyListeners();

      List<Video> videos;
      
      // If we don't have a lastDocument and lastVideoId is provided,
      // we need to fetch the document first
      if (_lastDocument == null && lastVideoId != null) {
        _lastDocument = await FirebaseFirestore.instance
            .collection('videos')
            .doc(lastVideoId)
            .get();
      }

      // Only call getNextVideos with lastVideo if we have a document
      if (_lastDocument != null) {
        videos = await _firestoreService.getNextVideos(
          lastVideo: _lastDocument!,
          limit: pageSize,
        );
      } else {
        // If no last document, start from the beginning
        videos = (await _firestoreService.streamVideos(limit: pageSize).first);
      }

      // Store the last document for next pagination
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
      _error = 'Failed to load videos: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> onVideoInteraction(Video video) async {
    // For home feed, we don't need to do anything special
    // The VideoCollectionManager handles likes/saves
  }

  @override
  bool shouldKeepVideo(Video video) => true; // Keep all videos in home feed

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
    return getNextPage(null, 10);
  }
} 