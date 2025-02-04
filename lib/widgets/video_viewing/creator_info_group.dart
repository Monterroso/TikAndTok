import 'package:flutter/material.dart';

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