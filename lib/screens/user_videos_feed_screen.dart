import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_videos_feed_controller.dart';
import '../controllers/video_collection_manager.dart';
import '../services/firestore_service.dart';
import 'video_viewing_screen.dart';

class UserVideosFeedScreen extends StatelessWidget {
  final String userId;
  final int initialVideoIndex;

  const UserVideosFeedScreen({
    super.key,
    required this.userId,
    required this.initialVideoIndex,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService().streamUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final userData = snapshot.data!.data();
        if (userData == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        final manager = context.read<VideoCollectionManager>();
        final controller = UserVideosFeedController(
          userId: userId,
          initialIndex: initialVideoIndex,
          collectionManager: manager,
          username: userData['username'] ?? 'Unknown User',
        );

        return VideoViewingScreen(
          feedController: controller,
          showBackButton: true,
        );
      },
    );
  }
} 