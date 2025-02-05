import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/video.dart';
import '../widgets/video_viewing/video_feed.dart';
import '../widgets/video_viewing/top_search_button.dart';
import '../widgets/video_viewing/right_actions_column.dart';
import '../widgets/video_viewing/creator_info_group.dart';
import '../widgets/video_viewing/custom_bottom_navigation_bar.dart';

/// FrontPage is the main entry point for the D&D TikTok clone's video display.
/// It sets up a layered UI using a full-screen stack:
/// - The VideoFeed provides a swipeable list of full-screen videos.
/// - The TopSearchButton is positioned at the top-right for searches.
/// - The RightActionsColumn displays buttons like, dislike, comments, save, share, 
///   and music info in a vertical column on the right edge.
/// - The CreatorInfoGroup shows the creator's profile picture, follow button, username,
///   and video title at the bottom-left.
/// - The CustomBottomNavigationBar is fixed at the bottom with upload and profile actions.
class FrontPage extends StatelessWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Debug information or VideoFeed
          StreamBuilder<List<Video>>(
            stream: FirestoreService().streamVideos(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Debug: Firebase Error\n${snapshot.error}',
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'Debug: Waiting for Firebase data...',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              final videos = snapshot.data ?? [];
              if (videos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Debug: No videos in Firebase\nCollection: videos\nExpected fields: url, userId, title, description',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return VideoFeed(
                videoUrls: videos.map((video) => video.url).toList(),
              );
            },
          ),
          
          // TopSearchButton positioned at the top-right with padding
          const Positioned(
            top: 16.0,
            right: 16.0,
            child: TopSearchButton(),
          ),
          
          // RightActionsColumn holds the interactive buttons
          const Positioned(
            top: 100.0,
            right: 16.0,
            bottom: 100.0,
            child: RightActionsColumn(),
          ),
          
          // CreatorInfoGroup displays creator details
          const Positioned(
            left: 16.0,
            bottom: 80.0,
            child: CreatorInfoGroup(),
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