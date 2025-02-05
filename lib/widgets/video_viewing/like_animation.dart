import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays a heart animation when a video is liked.
/// This includes both the persistent heart icon in the actions column
/// and the popup heart animation when double-tapping.
class LikeAnimation extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final Function() onTap;
  final bool showPopupAnimation;

  const LikeAnimation({
    Key? key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.showPopupAnimation = false,
  }) : super(key: key);

  @override
  State<LikeAnimation> createState() => _LikeAnimationState();
}

class _LikeAnimationState extends State<LikeAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    if (widget.showPopupAnimation) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LikeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      HapticFeedback.mediumImpact();
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            widget.onTap();
            HapticFeedback.mediumImpact();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.showPopupAnimation ? _scaleAnimation.value : 1.0,
                child: Opacity(
                  opacity: widget.showPopupAnimation ? _fadeAnimation.value : 1.0,
                  child: Icon(
                    widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.isLiked ? Colors.red : Colors.white,
                    size: 32.0,
                  ),
                ),
              );
            },
          ),
        ),
        if (!widget.showPopupAnimation) ...[
          const SizedBox(height: 4.0),
          Text(
            '${widget.likeCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.0,
            ),
          ),
        ],
      ],
    );
  }
} 