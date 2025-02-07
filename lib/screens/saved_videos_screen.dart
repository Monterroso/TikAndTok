import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/video_collection_manager.dart';
import '../widgets/video_viewing/video_grid.dart';
import '../models/video.dart';
import 'saved_videos_feed_screen.dart';

/// Represents the different types of video collections
enum CollectionType {
  liked(
    icon: Icons.favorite,
    emptyIcon: Icons.favorite_border,
    label: 'Liked',
    emptyMessage: 'No liked videos yet',
    removeMessage: 'Removed from liked videos'
  ),
  saved(
    icon: Icons.bookmark,
    emptyIcon: Icons.bookmark_border,
    label: 'Saved',
    emptyMessage: 'No saved videos yet',
    removeMessage: 'Removed from saved videos'
  );

  final IconData icon;
  final IconData emptyIcon;
  final String label;
  final String emptyMessage;
  final String removeMessage;

  const CollectionType({
    required this.icon,
    required this.emptyIcon,
    required this.label,
    required this.emptyMessage,
    required this.removeMessage,
  });

  // Get videos based on collection type
  List<Video> getVideos(VideoCollectionManager manager) {
    switch (this) {
      case CollectionType.liked:
        return manager.likedVideos;
      case CollectionType.saved:
        return manager.savedVideos;
    }
  }

  // Get loading state based on collection type
  bool isLoading(VideoCollectionManager manager) {
    switch (this) {
      case CollectionType.liked:
        return manager.isLoadingLiked;
      case CollectionType.saved:
        return manager.isLoadingSaved;
    }
  }

  // Fetch videos based on collection type
  void fetchVideos(VideoCollectionManager manager, String userId) {
    switch (this) {
      case CollectionType.liked:
        manager.fetchLikedVideos(userId);
        break;
      case CollectionType.saved:
        manager.fetchSavedVideos(userId);
        break;
    }
  }

  // Toggle video in collection
  Future<void> toggleVideo(VideoCollectionManager manager, String videoId, String userId) {
    switch (this) {
      case CollectionType.liked:
        return manager.toggleLikeVideo(videoId, userId);
      case CollectionType.saved:
        return manager.toggleSaveVideo(videoId, userId);
    }
  }
}

class SavedVideosScreen extends StatefulWidget {
  const SavedVideosScreen({Key? key}) : super(key: key);

  @override
  State<SavedVideosScreen> createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentUserId;
  final _tabs = CollectionType.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
          tabs: _tabs.map((type) => Tab(
            icon: Icon(type.icon),
            text: type.label,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((type) => _buildVideoGrid(type)).toList(),
      ),
    );
  }

  Widget _buildVideoGrid(CollectionType type) {
    return Consumer<VideoCollectionManager>(
      builder: (context, manager, child) {
        return VideoGrid(
          videos: type.getVideos(manager),
          isLoading: type.isLoading(manager),
          error: manager.error,
          onRetry: () {
            manager.clearError();
            type.fetchVideos(manager, _currentUserId);
          },
          emptyStateMessage: type.emptyMessage,
          emptyStateIcon: type.emptyIcon,
          actionBuilder: (video) => Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              onPressed: () async {
                try {
                  await type.toggleVideo(manager, video.id, _currentUserId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(type.removeMessage)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove video: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              tooltip: 'Remove video',
            ),
          ),
          onVideoTap: (video, index) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SavedVideosFeedScreen(
                  initialVideoIndex: index,
                  collectionType: type,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
