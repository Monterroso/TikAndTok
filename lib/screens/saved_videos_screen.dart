import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/video_collection_manager.dart';
import '../widgets/video_viewing/video_grid.dart';

class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({Key? key}) : super(key: key);

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // Initialize video collections when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = context.read<VideoCollectionManager>();
      manager.fetchLikedVideos(_currentUserId);
      manager.fetchSavedVideos(_currentUserId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Liked',
            ),
            Tab(
              icon: Icon(Icons.bookmark),
              text: 'Saved',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideoGrid(isLikedTab: true),
          _buildVideoGrid(isLikedTab: false),
        ],
      ),
    );
  }

  Widget _buildVideoGrid({required bool isLikedTab}) {
    return Consumer<VideoCollectionManager>(
      builder: (context, manager, child) {
        return VideoGrid(
          videos: isLikedTab ? manager.likedVideos : manager.savedVideos,
          isLoading: isLikedTab ? manager.isLoadingLiked : manager.isLoadingSaved,
          error: manager.error,
          onRetry: () {
            manager.clearError();
            if (isLikedTab) {
              manager.fetchLikedVideos(_currentUserId);
            } else {
              manager.fetchSavedVideos(_currentUserId);
            }
          },
          emptyStateMessage: isLikedTab ? 'No liked videos yet' : 'No saved videos yet',
          emptyStateIcon: isLikedTab ? Icons.favorite_border : Icons.bookmark_border,
          actionBuilder: (video) => IconButton(
            icon: const Icon(Icons.close),
            color: Colors.white,
            onPressed: () {
              if (isLikedTab) {
                manager.toggleLikeVideo(video.id, _currentUserId);
              } else {
                manager.toggleSaveVideo(video.id, _currentUserId);
              }
            },
          ),
          // TODO: Implement video player navigation
          onVideoTap: () {},
        );
      },
    );
  }
}
