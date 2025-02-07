import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../controllers/video_feed_controller.dart';
import 'video_background.dart';
import 'feed_header.dart';

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

class _VideoFeedState extends State<VideoFeed> {
  late PageController _pageController;
  final List<Video> _videos = [];
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
    _loadInitialVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialVideos() async {
    try {
      final videos = await widget.controller.getNextPage(null, 10);
      if (mounted) {
        setState(() {
          _videos.addAll(videos);
          _isInitialLoad = false;
        });
        if (_videos.isNotEmpty && widget.onVideoChanged != null) {
          widget.onVideoChanged!(_videos[0]);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e.toString();
          _isInitialLoad = false;
        });
      }
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
    // Filter out any videos that should no longer be shown
    final validVideos = _videos.where(
      (video) => widget.controller.shouldKeepVideo(video)
    ).toList();

    if (validVideos.length != _videos.length) {
      setState(() {
        _videos.clear();
        _videos.addAll(validVideos);
      });
      
      // Adjust index if needed
      if (index >= _videos.length) {
        index = _videos.length - 1;
        _pageController.jumpToPage(index);
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
    await widget.controller.onVideoInteraction(_videos[index]);
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
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return GestureDetector(
                      onDoubleTap: _handleDoubleTap,
                      child: VideoBackground(
                        videoUrl: video.url,
                      ),
                    );
                  },
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