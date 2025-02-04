import 'package:flutter/material.dart';

/// RightActionsColumn groups interactive buttons such as like, dislike, comments,
/// save, share, and music info vertically along the right edge.
class RightActionsColumn extends StatelessWidget {
  const RightActionsColumn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Like button with a numerical count displayed below.
        const _ActionButton(icon: Icons.thumb_up, count: 100),
        const SizedBox(height: 20.0),
        // Dislike button with a numerical count displayed below.
        const _ActionButton(icon: Icons.thumb_down, count: 10),
        const SizedBox(height: 20.0),
        // Comments button with a numerical count displayed below.
        const _ActionButton(icon: Icons.comment, count: 25),
        const SizedBox(height: 20.0),
        // Save button.
        IconButton(
          icon: const Icon(Icons.bookmark, color: Colors.white),
          onPressed: () {
            // TODO: Implement save functionality.
          },
        ),
        const SizedBox(height: 20.0),
        // Share button.
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // TODO: Implement share functionality.
          },
        ),
        const SizedBox(height: 20.0),
        // Music info button.
        IconButton(
          icon: const Icon(Icons.music_note, color: Colors.white),
          onPressed: () {
            // TODO: Display music information.
          },
        ),
      ],
    );
  }
}

/// _ActionButton is a reusable, private widget to render an icon button with a count.
/// It is used for like, dislike, and comments buttons.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () {
            // TODO: Implement action for the button.
          },
        ),
        Text(
          '$count',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
} 