import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/video_collection_manager.dart';
import '../controllers/saved_videos_feed_controller.dart';
import '../widgets/video_viewing/video_feed.dart';

class SavedVideosFeedScreen extends StatefulWidget {
  const SavedVideosFeedScreen({super.key});

  @override
  State<SavedVideosFeedScreen> createState() => _SavedVideosFeedScreenState();
}

class _SavedVideosFeedScreenState extends State<SavedVideosFeedScreen> {
  late SavedVideosFeedController _controller;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collectionManager = context.read<VideoCollectionManager>();
    
    _controller = SavedVideosFeedController(
      userId: userId,
      collectionManager: collectionManager,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VideoCollectionManager>(
        builder: (context, manager, child) {
          return VideoFeed(
            controller: _controller,
            onVideoChanged: (video) {
              // Update current video state if needed
            },
            onLikeChanged: (isLiked) async {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              try {
                await manager.toggleSaveVideo(
                  _controller.currentVideo?.id ?? '',
                  userId,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update save: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            isCurrentVideoLiked: manager.isVideoSaved(
              _controller.currentVideo?.id ?? '',
            ),
          );
        },
      ),
    );
  }
} 