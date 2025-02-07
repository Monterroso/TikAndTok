import 'package:flutter/material.dart';

/// A widget that handles the animation when a video is being removed from the feed
/// (e.g., when unliking a video in the liked videos feed)
class VideoRemovalAnimation extends StatefulWidget {
  final Widget child;
  final bool isRemoved;
  final VoidCallback? onRemovalComplete;
  final Duration duration;
  final Curve curve;

  const VideoRemovalAnimation({
    super.key,
    required this.child,
    required this.isRemoved,
    this.onRemovalComplete,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<VideoRemovalAnimation> createState() => _VideoRemovalAnimationState();
}

class _VideoRemovalAnimationState extends State<VideoRemovalAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.isRemoved) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(VideoRemovalAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRemoved && !oldWidget.isRemoved) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    widget.onRemovalComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
} 