import 'package:flutter/foundation.dart';
import '../models/video.dart';
import 'video_collection_manager.dart';

/// Abstract base class for video feed controllers.
/// Each feed type (Home, Liked, Saved) will implement this class.
abstract class VideoFeedController extends ChangeNotifier {
  final String feedTitle;
  final bool showBackButton;
  final VideoCollectionManager collectionManager;

  VideoFeedController({
    required this.feedTitle,
    required this.showBackButton,
    required this.collectionManager,
  });

  /// Fetches the next page of videos starting after the given video ID
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize);

  /// Called when a video interaction occurs (like, save, etc.)
  Future<void> onVideoInteraction(Video video);

  /// Checks if a video should be kept in the feed
  /// This is used for filtering videos that should no longer appear
  /// (e.g., unliked videos in the liked videos feed)
  bool shouldKeepVideo(Video video);

  /// Returns true if there are more videos to load
  bool get hasMoreVideos;

  /// Returns true if currently loading more videos
  bool get isLoading;

  /// Returns any error message, or null if no error
  String? get error;

  /// Clears any error message
  void clearError() {
    notifyListeners();
  }
} 