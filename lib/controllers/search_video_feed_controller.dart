import 'package:flutter/foundation.dart';
import '../models/video.dart';
import 'video_feed_controller.dart';
import 'video_collection_manager.dart';

class SearchVideoFeedController extends VideoFeedController {
  final List<Video> _searchResults;
  final int _initialIndex;
  bool _isLoading = false;
  String? _error;
  List<Video>? _videos;

  SearchVideoFeedController({
    required List<Video> searchResults,
    required int initialIndex,
    required VideoCollectionManager collectionManager,
  })  : _searchResults = searchResults,
        _initialIndex = initialIndex,
        super(
          feedTitle: 'Search Results',
          showBackButton: true,
          collectionManager: collectionManager,
        ) {
    // Initialize videos list immediately
    _videos = List<Video>.from(searchResults);
  }

  @override
  Future<List<Video>> getInitialVideos() async {
    if (_videos != null) {
      return _videos!;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Initialize videos if not already done
      _videos = List<Video>.from(_searchResults);
      
      return _videos!;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize) async {
    // No pagination in search results feed
    return [];
  }

  @override
  Future<void> onVideoInteraction(Video video) async {
    try {
      // Get the current video state
      final videoState = collectionManager.getCachedVideoState(video.id);
      if (videoState == null) return;

      // Update local state if needed
      final index = _videos?.indexWhere((v) => v.id == video.id) ?? -1;
      if (index != -1 && _videos != null) {
        _videos![index] = video;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling video interaction: $e');
    }
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

  int get initialIndex => _initialIndex;
} 