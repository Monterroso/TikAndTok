import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/video.dart';

/// VideoBackground is responsible for playing a single video in full screen.
/// It handles video playback, auto-play, and proper lifecycle management.
class VideoBackground extends StatefulWidget {
  final String? videoUrl;
  final VideoOrientation orientation;

  const VideoBackground({
    Key? key, 
    this.videoUrl,
    this.orientation = VideoOrientation.portrait,
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
      
      // Log video details after initialization
      final size = _controller!.value.size;
                  
      await _controller!.setLooping(true);
      await _controller!.play();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
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

    // Get video dimensions and screen size
    final videoSize = _controller!.value.size;
    final screenSize = MediaQuery.of(context).size;
    final videoAspectRatio = videoSize.width / videoSize.height;

    // Create the base video player widget
    Widget player = VideoPlayer(_controller!);

    // Determine if video should be rotated based on its natural dimensions
    final isNaturallyLandscape = videoAspectRatio > 1;
    final shouldRotate = isNaturallyLandscape;

    // For landscape videos, we need to rotate and scale
    if (shouldRotate) {
      // Calculate the scale factor to fill the screen height while maintaining aspect ratio
      final scale = screenSize.height / videoSize.width;
                  
      // Create a container that's as wide as the screen height and as tall as the screen width
      player = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: screenSize.height,
            height: screenSize.width,
            child: Transform.rotate(
              angle: -90 * 3.14159 / 180, // Rotate 90 degrees counterclockwise
              child: Transform.scale(
                scale: scale,
                child: AspectRatio(
                  aspectRatio: videoAspectRatio,
                  child: player,
                ),
              ),
            ),
          ),
        ),
      );
          } else {
            // For portrait videos, maintain original aspect ratio
      player = AspectRatio(
        aspectRatio: videoAspectRatio,
        child: player,
      );
    }
    
    return Container(
      color: Colors.black,
      child: player,
    );
  }
} 