import 'package:flutter/material.dart';

/// FrontPage is the main entry point for the D&D TikTok clone’s video display.
/// It sets up a layered UI using a full-screen stack:
/// - The VideoBackground plays the video in full-screen behind all UI elements.
/// - The TopSearchButton is positioned at the top-right for searches.
/// - The RightActionsColumn displays buttons like, dislike, comments, save, share, 
///   and music info in a vertical column on the right edge.
/// - The CreatorInfoGroup shows the creator’s profile picture, follow button, username,
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

/// VideoBackground acts as a placeholder for the full-screen video.
/// In a complete implementation, replace this with a video player widget.
class VideoBackground extends StatelessWidget {
  const VideoBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Placeholder: represents video content.
    );
  }
}

/// TopSearchButton represents the search functionality located at the top-right.
class TopSearchButton extends StatelessWidget {
  const TopSearchButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white),
      onPressed: () {
        // TODO: Implement search functionality.
      },
    );
  }
}

/// RightActionsColumn groups interactive buttons such as like, dislike, comments,
/// save, share, and music info vertically along the right edge.
class RightActionsColumn extends StatelessWidget {
  const RightActionsColumn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Like button with a numerical count displayed below.
        const _ActionButton(icon: Icons.thumb_up, count: 100),
        const SizedBox(height: 20.0),
        // Dislike button with a numerical count displayed below.
        const _ActionButton(icon: Icons.thumb_down, count: 10),
        const SizedBox(height: 20.0),
        // Comments button with a numerical count displayed below.
        const _ActionButton(icon: Icons.comment, count: 25),
        const SizedBox(height: 20.0),
        // Save button.
        IconButton(
          icon: const Icon(Icons.bookmark, color: Colors.white),
          onPressed: () {
            // TODO: Implement save functionality.
          },
        ),
        const SizedBox(height: 20.0),
        // Share button.
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // TODO: Implement share functionality.
          },
        ),
        const SizedBox(height: 20.0),
        // Music info button.
        IconButton(
          icon: const Icon(Icons.music_note, color: Colors.white),
          onPressed: () {
            // TODO: Display music information.
          },
        ),
      ],
    );
  }
}

/// _ActionButton is a reusable, private widget to render an icon button with a count.
/// It is used for like, dislike, and comments buttons.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () {
            // TODO: Implement action for the button with the $icon icon.
          },
        ),
        Text(
          '$count',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

/// CreatorInfoGroup shows details about the video creator such as profile picture,
/// follow button, username, and video title. It is positioned at the bottom-left.
class CreatorInfoGroup extends StatelessWidget {
  const CreatorInfoGroup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A row containing the profile picture and the follow button.
        Row(
          children: [
            const CircleAvatar(
              radius: 24.0,
              backgroundColor: Colors.grey, // Placeholder for the image.
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement follow or unfollow functionality.
              },
              child: const Text('Follow'),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        // Display the username of the creator.
        const Text(
          'Username',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        // Display the title of the video.
        const Text(
          'Video Title goes here',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

/// CustomBottomNavigationBar sets up a fixed navigation bar at the bottom of the screen.
/// It includes an upload button (centered) and a profile button (aligned to the right).
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Spacer to help center the upload button.
          const Expanded(child: SizedBox()),
          // Centered upload button.
          ElevatedButton(
            onPressed: () {
              // TODO: Implement upload functionality.
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
          // Profile button aligned to the right.
          const Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}