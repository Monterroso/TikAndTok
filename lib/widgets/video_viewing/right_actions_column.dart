import 'package:flutter/material.dart';
import '../../models/video.dart';
import 'like_animation.dart';
import 'comments/comments_sheet.dart';

/// RightActionsColumn groups interactive buttons such as like, comments,
/// save, share, and music info vertically along the right edge.
class RightActionsColumn extends StatelessWidget {
  final Video video;
  final String currentUserId;
  final Function(bool) onLikeChanged;
  final bool isLiked;
  final int likeCount;

  const RightActionsColumn({
    Key? key,
    required this.video,
    required this.currentUserId,
    required this.onLikeChanged,
    required this.isLiked,
    required this.likeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Like button with animation
        LikeAnimation(
          isLiked: isLiked,
          likeCount: likeCount,
          onTap: () => onLikeChanged(!isLiked),
        ),
        const SizedBox(height: 20.0),
        // Comments button with a numerical count displayed below.
        _ActionButton(
          icon: Icons.comment,
          count: video.comments,
          onTap: () => CommentsSheet.show(
            context: context,
            videoId: video.id,
            currentUserId: currentUserId,
            commentCount: video.comments,
          ),
        ),
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
/// It is used for comments and other countable actions.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback? onTap;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.count,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onTap,
        ),
        Text(
          '$count',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
} 