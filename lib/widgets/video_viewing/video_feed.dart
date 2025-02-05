import 'package:flutter/material.dart';
import 'video_background.dart';

/// VideoFeed implements a vertically scrollable feed of videos.
/// It uses PageView for smooth transitions and manages video loading.
class VideoFeed extends StatefulWidget {
  final List<String> videoUrls;

  const VideoFeed({
    Key? key,
    required this.videoUrls,
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
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.videoUrls.length,
      itemBuilder: (context, index) {
        return VideoBackground(
          videoUrl: widget.videoUrls[index],
        );
      },
    );
  }
} 