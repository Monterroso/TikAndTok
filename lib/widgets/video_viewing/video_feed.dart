import 'package:flutter/material.dart';
import '../../models/video.dart';
import 'video_background.dart';
import 'like_animation.dart';

/// VideoFeed implements a vertically scrollable feed of videos.
/// It uses PageView for smooth transitions and manages video loading.
class VideoFeed extends StatefulWidget {
  final List<Video> videos;
  final Function(Video)? onVideoChanged;
  final Function(bool)? onLikeChanged;
  final bool isCurrentVideoLiked;
  final int currentVideoLikeCount;

  const VideoFeed({
    Key? key,
    required this.videos,
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
  int _currentPageIndex = 0;
  bool _showDoubleTapLike = false;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Schedule the initial video notification for after the build
    if (widget.videos.isNotEmpty && widget.onVideoChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVideoChanged!(widget.videos[0]);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      _showDoubleTapLike = false;
    });
    // Notify video change
    if (widget.onVideoChanged != null) {
      widget.onVideoChanged!(widget.videos[index]);
    }
    // TODO: Implement prefetching of next video's creator data
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (widget.onLikeChanged != null) {
      // Toggle the like status
      widget.onLikeChanged!(!widget.isCurrentVideoLiked);
      
      // Only show the animation when liking, not unliking
      if (!widget.isCurrentVideoLiked) {
        setState(() {
          _showDoubleTapLike = true;
          _doubleTapPosition = details.localPosition;
        });
        // Hide the animation after it completes
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showDoubleTapLike = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        return GestureDetector(
          onDoubleTapDown: _handleDoubleTap,
          onDoubleTap: () {}, // Required to detect double tap
          child: Stack(
            children: [
              VideoBackground(
                videoUrl: video.url,
              ),
              if (_showDoubleTapLike && index == _currentPageIndex)
                Positioned(
                  left: _doubleTapPosition.dx - 40, // Center the heart
                  top: _doubleTapPosition.dy - 40,
                  child: LikeAnimation(
                    isLiked: true,
                    likeCount: widget.currentVideoLikeCount,
                    onTap: () {}, // No-op since this is just for animation
                    showPopupAnimation: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 