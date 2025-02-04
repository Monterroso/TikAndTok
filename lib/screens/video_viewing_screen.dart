import 'package:flutter/material.dart';
import '../widgets/video_viewing/video_background.dart';
import '../widgets/video_viewing/top_search_button.dart';
import '../widgets/video_viewing/right_actions_column.dart';
import '../widgets/video_viewing/creator_info_group.dart';
import '../widgets/video_viewing/custom_bottom_navigation_bar.dart';

/// FrontPage is the main entry point for the D&D TikTok clone's video display.
/// It sets up a layered UI using a full-screen stack:
/// - The VideoBackground plays the video in full-screen behind all UI elements.
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
      // Using a Stack to layer the video and overlay components.
      body: Stack(
        children: [
          // VideoBackground occupies the full screen.
          const VideoBackground(),
          // TopSearchButton positioned at the top-right with padding.
          const Positioned(
            top: 16.0,
            right: 16.0,
            child: TopSearchButton(),
          ),
          // RightActionsColumn holds the interactive buttons, vertically aligned.
          const Positioned(
            top: 100.0,
            right: 16.0,
            bottom: 100.0,
            child: RightActionsColumn(),
          ),
          // CreatorInfoGroup displays creator details and video info at bottom-left.
          const Positioned(
            left: 16.0,
            bottom: 80.0, // Leaves space for the bottom navigation.
            child: CreatorInfoGroup(),
          ),
          // CustomBottomNavigationBar fixed at the bottom of the screen.
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