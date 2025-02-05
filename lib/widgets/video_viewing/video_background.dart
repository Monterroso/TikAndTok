import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// VideoBackground is responsible for playing a single video in full screen.
/// It handles video playback, auto-play, and proper lifecycle management.
class VideoBackground extends StatefulWidget {
  final String? videoUrl;

  const VideoBackground({
    Key? key, 
    this.videoUrl,
  }) : super(key: key);

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // For testing, use a sample video if no URL is provided
    final videoUrl = widget.videoUrl ?? 
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
    
    _controller = VideoPlayerController.network(videoUrl);

    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      // We'll show an error icon in the build method
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: _buildVideoWidget(),
    );
  }

  Widget _buildVideoWidget() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_controller.value.hasError) {
      return const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 48,
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
} 