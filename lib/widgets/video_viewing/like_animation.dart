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
  bool _wasLiked = false;

  @override
  void initState() {
    super.initState();
    _wasLiked = widget.isLiked;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
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
      // Only play animation when liking, not unliking
      if (widget.isLiked) {
        _controller.forward(from: 0.0);
      }
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
            // Play animation when tapping to like
            if (!widget.isLiked) {
              _controller.forward(from: 0.0);
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = widget.showPopupAnimation 
                ? _scaleAnimation.value 
                : (widget.isLiked && _controller.isAnimating 
                    ? _scaleAnimation.value 
                    : 1.0);
              
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Regular heart icon with color animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey<bool>(widget.isLiked),
                        color: widget.isLiked ? Colors.red : Colors.white,
                        size: 32.0,
                      ),
                    ),
                    // Popup heart that fades out
                    if (widget.showPopupAnimation)
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 80.0,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (!widget.showPopupAnimation) ...[
          const SizedBox(height: 4.0),
          // Animate the like count changes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              '${widget.likeCount}',
              key: ValueKey<int>(widget.likeCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
} 