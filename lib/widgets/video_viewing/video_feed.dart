import 'package:flutter/material.dart';
import '../../models/video.dart';
import 'video_background.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    });
    if (widget.onVideoChanged != null) {
      widget.onVideoChanged!(widget.videos[index]);
    }
  }

  void _handleDoubleTap() {
    if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(!widget.isCurrentVideoLiked);
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
          onDoubleTap: _handleDoubleTap,
          child: VideoBackground(
            videoUrl: video.url,
          ),
        );
      },
    );
  }
} 