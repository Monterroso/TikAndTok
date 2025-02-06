import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays an animated icon for video interactions like likes and saves.
/// This includes both the persistent icon in the actions column
/// and optional popup animations when interacting.
class InteractionAnimation extends StatefulWidget {
  final bool isActive;
  final int count;
  final Function() onTap;
  final bool showPopupAnimation;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final Color inactiveColor;
  final bool showCount;

  const InteractionAnimation({
    Key? key,
    required this.isActive,
    required this.count,
    required this.onTap,
    this.showPopupAnimation = false,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.activeColor,
    this.inactiveColor = Colors.white,
    this.showCount = true,
  }) : super(key: key);

  @override
  State<InteractionAnimation> createState() => _InteractionAnimationState();
}

class _InteractionAnimationState extends State<InteractionAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InteractionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
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
            _controller.forward(from: 0.0);
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.inactiveIcon,
                  size: 35.0,
                  color: widget.isActive ? widget.activeColor : widget.inactiveColor,
                ),
              );
            },
          ),
        ),
        if (widget.showCount) ...[
          const SizedBox(height: 5.0),
          Text(
            '${widget.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
} 