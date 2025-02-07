import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_videos_feed_controller.dart';
import '../controllers/video_collection_manager.dart';
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
    final manager = context.read<VideoCollectionManager>();
    final controller = UserVideosFeedController(
      userId: userId,
      initialIndex: initialVideoIndex,
      collectionManager: manager,
    );

    return VideoViewingScreen(feedController: controller);
  }
} 