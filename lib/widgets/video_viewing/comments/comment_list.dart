import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/comment.dart';
import '../../../services/firestore_service.dart';
import 'comment_tile.dart';

/// A scrollable list of comments for a video
class CommentList extends StatelessWidget {
  final String videoId;
  final String currentUserId;

  const CommentList({
    super.key,
    required this.videoId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream: FirestoreService().streamComments(videoId: videoId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return const Center(
            child: Text('No comments yet. Be the first to comment!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return CommentTile(
              comment: comment,
              isCurrentUser: comment.userId == currentUserId,
              onDelete: comment.userId == currentUserId
                  ? () => _handleDeleteComment(context, comment)
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteComment(BuildContext context, Comment comment) async {
    try {
      await FirestoreService().deleteComment(
        videoId: videoId,
        commentId: comment.id,
        userId: currentUserId,
      );
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }
} 