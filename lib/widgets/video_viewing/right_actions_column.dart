import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../services/firestore_service.dart';
import 'interaction_animation.dart';
import 'comments/comments_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'technical_details_sheet.dart';
import 'technical_metadata_display.dart';

/// RightActionsColumn groups interactive buttons such as like, comments,
/// save, share, and music info vertically along the right edge.
class RightActionsColumn extends StatelessWidget {
  final Video video;
  final String currentUserId;
  final Function(bool) onLikeChanged;
  final Function(bool) onSaveChanged;
  final bool isLiked;
  final bool isSaved;
  final int likeCount;
  final int saveCount;

  const RightActionsColumn({
    Key? key,
    required this.video,
    required this.currentUserId,
    required this.onLikeChanged,
    required this.onSaveChanged,
    required this.isLiked,
    required this.isSaved,
    required this.likeCount,
    required this.saveCount,
  }) : super(key: key);

  void _showTechnicalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Technical Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Technical metadata content in an expanded scrollview
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TechnicalMetadataDisplay(videoId: video.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().streamVideoDocument(video.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              Text('Error: ${snapshot.error}', 
                style: const TextStyle(color: Colors.red),
              ),
            ],
          );
        }

        // Use video.comments as fallback while loading or if data is null
        final stats = snapshot.hasData 
            ? FirestoreService().getStatsFromDoc(snapshot.data!)
            : {'comments': video.comments};
        final commentCount = stats['comments'] as int? ?? 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Like button with animation
            InteractionAnimation(
              isActive: isLiked,
              count: likeCount,
              onTap: () => onLikeChanged(!isLiked),
              activeIcon: Icons.favorite,
              inactiveIcon: Icons.favorite_border,
              activeColor: Colors.red,
            ),
            const SizedBox(height: 20.0),
            // Comments button with a numerical count displayed below.
            _ActionButton(
              icon: Icons.comment,
              count: commentCount,
              onTap: () => CommentsSheet.show(
                context: context,
                videoId: video.id,
                currentUserId: currentUserId,
                commentCount: commentCount,
              ),
            ),
            const SizedBox(height: 20.0),
            // Save button with animation
            InteractionAnimation(
              isActive: isSaved,
              count: saveCount,
              onTap: () => onSaveChanged(!isSaved),
              activeIcon: Icons.bookmark,
              inactiveIcon: Icons.bookmark_border,
              activeColor: Colors.amber,
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
            const SizedBox(height: 20.0),
            // Technical details button.
            InteractionAnimation(
              isActive: false,
              onTap: () => _showTechnicalDetails(context),
              activeIcon: Icons.code,
              inactiveIcon: Icons.code,
              activeColor: Colors.white,
              showCount: false,
              count: 0,
            ),
          ],
        );
      },
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