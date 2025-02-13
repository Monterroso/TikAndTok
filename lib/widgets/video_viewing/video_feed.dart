import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../controllers/video_feed_controller.dart';
import 'video_background.dart';
import 'feed_header.dart';
import 'video_removal_animation.dart';

/// VideoFeed implements a vertically scrollable feed of videos.
/// It uses PageView for smooth transitions and manages video loading.
class VideoFeed extends StatefulWidget {
  final VideoFeedController controller;
  final Function(Video)? onVideoChanged;
  final Function(bool)? onLikeChanged;
  final bool isCurrentVideoLiked;
  final int currentVideoLikeCount;
  final int? initialIndex;

  const VideoFeed({
    super.key,
    required this.controller,
    this.onVideoChanged,
    this.onLikeChanged,
    this.isCurrentVideoLiked = false,
    this.currentVideoLikeCount = 0,
    this.initialIndex,
  });

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> with TickerProviderStateMixin {
  late PageController _pageController;
  final List<Video> _videos = [];
  final Map<String, bool> _removedVideos = {};
  int _currentPageIndex = 0;
  bool _isLoadingMore = false;
  bool _isInitialLoad = true;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex ?? 0,
    );
    // Schedule the load for after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVideos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialVideos() async {
    if (!mounted) return;
    
    try {
      final videos = await widget.controller.getInitialVideos();
      if (!mounted) return;
      
      setState(() {
        _videos.addAll(videos);
        _isInitialLoad = false;
      });

      if (_videos.isNotEmpty && widget.onVideoChanged != null) {
        final initialIndex = widget.initialIndex ?? 0;
        widget.onVideoChanged!(_videos[initialIndex]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastError = e.toString();
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !widget.controller.hasMoreVideos) return;

    setState(() {
      _isLoadingMore = true;
      _lastError = null;
    });

    try {
      final lastVideoId = _videos.isNotEmpty ? _videos.last.id : null;
      final newVideos = await widget.controller.getNextPage(lastVideoId, 10);
      
      if (mounted) {
        setState(() {
          _videos.addAll(newVideos.where(
            (video) => widget.controller.shouldKeepVideo(video)
          ));
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e.toString();
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onPageChanged(int index) async {
    // Check if the current video should be removed
    if (_currentPageIndex < _videos.length) {
      final currentVideo = _videos[_currentPageIndex];
      if (!widget.controller.shouldKeepVideo(currentVideo)) {
        setState(() {
          _removedVideos[currentVideo.id] = true;
        });
      }
    }

    setState(() {
      _currentPageIndex = index;
    });
    
    if (widget.onVideoChanged != null && index < _videos.length) {
      widget.onVideoChanged!(_videos[index]);
    }

    // Load more videos when we're near the end
    if (index >= _videos.length - 3) {
      await _loadMoreVideos();
    }

    // Handle video interaction if needed
    if (index < _videos.length) {
      await widget.controller.onVideoInteraction(_videos[index]);
    }
  }

  void _handleVideoRemovalComplete(String videoId) {
    setState(() {
      _videos.removeWhere((video) => video.id == videoId);
      _removedVideos.remove(videoId);
    });
  }

  void _handleDoubleTap() {
    if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(!widget.isCurrentVideoLiked);
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVideoItem(Video video, int index) {
    final isRemoved = _removedVideos[video.id] ?? false;
    
    return VideoRemovalAnimation(
      key: ValueKey(video.id),
      isRemoved: isRemoved,
      onRemovalComplete: () => _handleVideoRemovalComplete(video.id),
      child: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        child: VideoBackground(
          videoUrl: video.url,
          orientation: video.orientation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.controller.showBackButton)
          FeedHeader(
            title: widget.controller.feedTitle,
            showBackButton: true,
          ),
        Expanded(
          child: Stack(
            children: [
              if (_isInitialLoad)
                _buildLoadingIndicator()
              else if (_videos.isEmpty && _lastError == null)
                Center(
                  child: Text(
                    'No videos found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              else
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _videos.length,
                  itemBuilder: (context, index) => _buildVideoItem(_videos[index], index),
                ),
              if (_isLoadingMore)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: _buildLoadingIndicator(),
                ),
              if (_lastError != null)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: _buildErrorMessage(_lastError!),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 