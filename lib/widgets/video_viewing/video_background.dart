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
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initializeVideo();
    } else {
      setState(() {
        _error = 'No video available';
      });
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl!);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _error = 'Unable to load video';
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
    // Show error state with custom message
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Show loading state
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    // Show video
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
} 