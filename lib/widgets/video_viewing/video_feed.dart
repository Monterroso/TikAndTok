import 'package:flutter/material.dart';
import '../../models/video.dart';
import 'video_background.dart';

/// VideoFeed implements a vertically scrollable feed of videos.
/// It uses PageView for smooth transitions and manages video loading.
class VideoFeed extends StatefulWidget {
  final List<Video> videos;
  final Function(Video)? onVideoChanged;

  const VideoFeed({
    Key? key,
    required this.videos,
    this.onVideoChanged,
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
    });
    // Notify video change
    if (widget.onVideoChanged != null) {
      widget.onVideoChanged!(widget.videos[index]);
    }
    // TODO: Implement prefetching of next video's creator data
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
        return VideoBackground(
          videoUrl: video.url,
          // Pass additional video metadata if needed by VideoBackground
        );
      },
    );
  }
} 