import 'package:flutter/material.dart';

/// A header widget for filtered video feeds (liked, saved, etc.)
/// Shows a title and back button, with consistent styling across feeds
class FeedHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const FeedHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 48.0), // Same width as IconButton for alignment
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48.0), // Balance the layout
        ],
      ),
    );
  }
} 