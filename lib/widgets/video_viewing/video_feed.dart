import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../controllers/video_feed_controller.dart';
import 'video_background.dart';

/// VideoFeed implements a vertically scrollable feed of videos.
/// It uses PageView for smooth transitions and manages video loading.
class VideoFeed extends StatefulWidget {
  final VideoFeedController controller;
  final Function(Video)? onVideoChanged;
  final Function(bool)? onLikeChanged;
  final bool isCurrentVideoLiked;
  final int currentVideoLikeCount;

  const VideoFeed({
    Key? key,
    required this.controller,
    this.onVideoChanged,
    this.onLikeChanged,
    this.isCurrentVideoLiked = false,
    this.currentVideoLikeCount = 0,
  }) : super(key: key);

  @override
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  late PageController _pageController;
  final List<Video> _videos = [];
  int _currentPageIndex = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialVideos() async {
    final videos = await widget.controller.getNextPage(null, 10);
    if (mounted) {
      setState(() {
        _videos.addAll(videos);
      });
      if (_videos.isNotEmpty && widget.onVideoChanged != null) {
        widget.onVideoChanged!(_videos[0]);
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !widget.controller.hasMoreVideos) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final lastVideoId = _videos.isNotEmpty ? _videos.last.id : null;
      final newVideos = await widget.controller.getNextPage(lastVideoId, 10);
      
      if (mounted) {
        setState(() {
          _videos.addAll(newVideos);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    
    if (widget.onVideoChanged != null) {
      widget.onVideoChanged!(_videos[index]);
    }

    // Load more videos when we're near the end
    if (index >= _videos.length - 3) {
      _loadMoreVideos();
    }
  }

  void _handleDoubleTap() {
    if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(!widget.isCurrentVideoLiked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
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
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (widget.controller.error != null)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.controller.error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
} 