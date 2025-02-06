import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment_list.dart';
import 'comment_input.dart';

/// A bottom sheet that displays comments for a video
class CommentsSheet extends StatelessWidget {
  final String videoId;
  final String currentUserId;
  final int commentCount;

  const CommentsSheet({
    super.key,
    required this.videoId,
    required this.currentUserId,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirestoreService().streamVideoDocument(videoId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Error loading comments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }

              // Use initial commentCount as fallback while loading or if data is null
              final stats = snapshot.hasData 
                  ? FirestoreService().getStatsFromDoc(snapshot.data!)
                  : {'comments': commentCount};
              final currentCommentCount = stats['comments'] as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '$currentCommentCount Comments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Comment List
          Expanded(
            child: CommentList(
              videoId: videoId,
              currentUserId: currentUserId,
            ),
          ),
          // Input Field
          CommentInput(
            videoId: videoId,
            userId: currentUserId,
          ),
        ],
      ),
    );
  }

  /// Shows this sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String videoId,
    required String currentUserId,
    required int commentCount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => CommentsSheet(
        videoId: videoId,
        currentUserId: currentUserId,
        commentCount: commentCount,
      ),
    );
  }
} 