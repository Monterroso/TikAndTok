import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/video_collection_manager.dart';
import '../controllers/saved_videos_feed_controller.dart';
import '../widgets/video_viewing/video_feed.dart';
import '../widgets/video_viewing/right_actions_column.dart';
import '../widgets/video_viewing/creator_info_group.dart';
import '../models/video.dart';
import 'saved_videos_screen.dart';

class SavedVideosFeedScreen extends StatefulWidget {
  final int initialVideoIndex;
  final CollectionType collectionType;

  const SavedVideosFeedScreen({
    super.key,
    required this.initialVideoIndex,
    required this.collectionType,
  });

  @override
  State<SavedVideosFeedScreen> createState() => _SavedVideosFeedScreenState();
}

class _SavedVideosFeedScreenState extends State<SavedVideosFeedScreen> {
  late SavedVideosFeedController _controller;
  Video? _currentVideo;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collectionManager = context.read<VideoCollectionManager>();
    
    _controller = SavedVideosFeedController(
      userId: userId,
      collectionManager: collectionManager,
      initialIndex: widget.initialVideoIndex,
      collectionType: widget.collectionType,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.collectionType.label,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Consumer<VideoCollectionManager>(
            builder: (context, manager, child) {
              return VideoFeed(
                controller: _controller,
                onVideoChanged: (video) {
                  setState(() {
                    _currentVideo = video;
                  });
                },
                onLikeChanged: (isLiked) async {
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  try {
                    await widget.collectionType.toggleVideo(
                      manager,
                      _currentVideo?.id ?? '',
                      userId,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update ${widget.collectionType.label.toLowerCase()}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                isCurrentVideoLiked: widget.collectionType == CollectionType.liked
                  ? manager.getCachedVideoState(_currentVideo?.id ?? '')?.isLiked ?? false
                  : manager.getCachedVideoState(_currentVideo?.id ?? '')?.isSaved ?? false,
              );
            },
          ),
          
          // Add right actions column for interactions
          if (_currentVideo != null) Positioned(
            top: 100.0,
            right: 16.0,
            bottom: 100.0,
            child: Consumer<VideoCollectionManager>(
              builder: (context, manager, child) {
                return RightActionsColumn(
                  video: _currentVideo!,
                  currentUserId: FirebaseAuth.instance.currentUser!.uid,
                  onLikeChanged: (liked) {
                    manager.toggleLikeVideo(
                      _currentVideo!.id,
                      FirebaseAuth.instance.currentUser!.uid,
                    );
                  },
                  onSaveChanged: (saved) {
                    manager.toggleSaveVideo(
                      _currentVideo!.id,
                      FirebaseAuth.instance.currentUser!.uid,
                    );
                  },
                  isLiked: manager.getCachedVideoState(_currentVideo!.id)?.isLiked ?? false,
                  isSaved: manager.getCachedVideoState(_currentVideo!.id)?.isSaved ?? false,
                  likeCount: manager.getLikeCount(_currentVideo!.id),
                  saveCount: manager.getSaveCount(_currentVideo!.id),
                );
              },
            ),
          ),
          
          // Add creator info at the bottom
          if (_currentVideo != null) Positioned(
            left: 16.0,
            right: 72.0,
            bottom: 80.0,
            child: CreatorInfoGroup(video: _currentVideo!),
          ),
        ],
      ),
    );
  }
} 