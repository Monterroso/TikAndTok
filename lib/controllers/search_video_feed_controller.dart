import 'package:flutter/foundation.dart';
import '../models/video.dart';
import 'video_feed_controller.dart';
import 'video_collection_manager.dart';

class SearchVideoFeedController extends VideoFeedController {
  final List<Video> _searchResults;
  final int _initialIndex;
  final VideoCollectionManager _collectionManager;
  bool _isLoading = false;
  String? _error;

  SearchVideoFeedController({
    required List<Video> searchResults,
    required int initialIndex,
    required VideoCollectionManager collectionManager,
  })  : _searchResults = searchResults,
        _initialIndex = initialIndex,
        _collectionManager = collectionManager,
        super(
          feedTitle: 'Search Results',
          showBackButton: true,
          collectionManager: collectionManager,
        );

  @override
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize) async {
    // No pagination in search results feed
    return [];
  }

  @override
  Future<void> onVideoInteraction(Video video) async {
    // Handle video interactions through collection manager
    notifyListeners();
  }

  @override
  bool shouldKeepVideo(Video video) => true;

  @override
  bool get hasMoreVideos => false;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<List<Video>> getInitialVideos() async {
    return _searchResults;
  }

  int get initialIndex => _initialIndex;
} 