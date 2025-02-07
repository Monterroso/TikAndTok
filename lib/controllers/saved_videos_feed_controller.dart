import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';
import 'video_feed_controller.dart';
import 'video_collection_manager.dart';
import 'package:flutter/material.dart';
import '../screens/saved_videos_screen.dart';

class SavedVideosFeedController extends VideoFeedController {
  final FirestoreService _firestoreService;
  final String _userId;
  final VideoCollectionManager _collectionManager;
  final CollectionType collectionType;
  final int initialIndex;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  Video? _currentVideo;

  SavedVideosFeedController({
    required String userId,
    required VideoCollectionManager collectionManager,
    required this.collectionType,
    required this.initialIndex,
    FirestoreService? firestoreService,
  }) : _userId = userId,
       _collectionManager = collectionManager,
       _firestoreService = firestoreService ?? FirestoreService(),
       super(
         feedTitle: 'Saved Videos',
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

      // Get saved videos from cache
      final savedVideoIds = _collectionManager.getSavedVideoIds(_userId);
      
      if (savedVideoIds.isEmpty) {
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

      // Get the next batch of videos that are in the savedVideoIds set
      if (_lastDocument != null) {
        videos = await _firestoreService.getNextFilteredVideos(
          lastVideo: _lastDocument!,
          limit: pageSize,
          filterIds: savedVideoIds,
        );
      } else {
        // If no last document, start from the beginning
        videos = await _firestoreService.getVideosByIds(
          videoIds: savedVideoIds.take(pageSize).toList(),
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
      _error = 'Failed to load saved videos: $e';
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
    // Only keep videos that are still saved
    return _collectionManager.isVideoSaved(video.id);
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
  Future<List<Video>> fetchVideos() async {
    // First ensure the videos are loaded
    switch (collectionType) {
      case CollectionType.liked:
        await _collectionManager.fetchLikedVideos(_userId);
        return _collectionManager.likedVideos;
      case CollectionType.saved:
        await _collectionManager.fetchSavedVideos(_userId);
        return _collectionManager.savedVideos;
    }
  }

  @override
  int get initialPage => initialIndex;
} 