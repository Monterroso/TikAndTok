import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/video.dart';
import '../controllers/video_collection_manager.dart';
import '../controllers/home_feed_controller.dart';
import '../widgets/video_viewing/video_feed.dart';
import '../widgets/video_viewing/top_search_button.dart';
import '../widgets/video_viewing/right_actions_column.dart';
import '../widgets/video_viewing/creator_info_group.dart';
import '../widgets/video_viewing/custom_bottom_navigation_bar.dart';

/// FrontPage is the main entry point for the D&D TikTok clone's video display.
/// It sets up a layered UI using a full-screen stack:
/// - The VideoFeed provides a swipeable list of full-screen videos.
/// - The TopSearchButton is positioned at the top-right for searches.
/// - The RightActionsColumn displays buttons for like, comments, save, share, 
///   and music info in a vertical column on the right edge.
/// - The CreatorInfoGroup shows the creator's profile picture, follow button, username,
///   and video title at the bottom-left.
/// - The CustomBottomNavigationBar is fixed at the bottom with upload and profile actions.
class FrontPage extends StatefulWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  Video? _currentVideo;
  HomeFeedController? _homeFeedController;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_homeFeedController == null) {
      final manager = context.read<VideoCollectionManager>();
      _homeFeedController = HomeFeedController(collectionManager: manager);
    }
  }

  void _handleVideoChanged(Video video) {
    if (!mounted) return;
    setState(() {
      _currentVideo = video;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Please sign in to view videos',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final manager = context.watch<VideoCollectionManager>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_homeFeedController != null) VideoFeed(
            controller: _homeFeedController!,
            onVideoChanged: _handleVideoChanged,
            onLikeChanged: (liked) {
              if (_currentVideo != null) {
                // Fire and forget - don't await
                manager.toggleLikeVideo(_currentVideo!.id, _currentUserId!);
              }
            },
            isCurrentVideoLiked: _currentVideo != null ? 
              (manager.getCachedVideoState(_currentVideo!.id)?.isLiked ?? false) : false,
            currentVideoLikeCount: _currentVideo != null ? 
              manager.getLikeCount(_currentVideo!.id) : 0,
          ),
          
          // TopSearchButton positioned at the top-right with padding
          const Positioned(
            top: 16.0,
            right: 16.0,
            child: TopSearchButton(),
          ),
          
          // RightActionsColumn holds the interactive buttons
          if (_currentVideo != null) Positioned(
            top: 100.0,
            right: 16.0,
            bottom: 100.0,
            child: RightActionsColumn(
              video: _currentVideo!,
              currentUserId: _currentUserId,
              onLikeChanged: (liked) {
                // Fire and forget - don't await
                manager.toggleLikeVideo(_currentVideo!.id, _currentUserId!);
              },
              onSaveChanged: (saved) {
                // Fire and forget - don't await
                manager.toggleSaveVideo(_currentVideo!.id, _currentUserId!);
              },
              isLiked: manager.getCachedVideoState(_currentVideo!.id)?.isLiked ?? false,
              isSaved: manager.getCachedVideoState(_currentVideo!.id)?.isSaved ?? false,
              likeCount: manager.getLikeCount(_currentVideo!.id),
              saveCount: manager.getSaveCount(_currentVideo!.id),
            ),
          ),
          
          // CreatorInfoGroup displays creator details
          Positioned(
            left: 16.0,
            right: 72.0, // Give space for the right action buttons
            bottom: 80.0,
            child: CreatorInfoGroup(video: _currentVideo),
          ),
          
          // CustomBottomNavigationBar fixed at the bottom
          const Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: CustomBottomNavigationBar(),
          ),
        ],
      ),
    );
  }
} 