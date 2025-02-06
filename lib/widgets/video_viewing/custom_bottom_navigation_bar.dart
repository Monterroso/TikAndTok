import 'package:flutter/material.dart';
import '../../screens/profile_screen.dart';
import '../../screens/saved_videos_screen.dart';

/// CustomBottomNavigationBar sets up a fixed navigation bar at the bottom of the screen.
/// It includes:
/// - Collections button (left-aligned)
/// - Upload button (centered)
/// - Profile button (right-aligned)
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Collections button on the left
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.collections_bookmark, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedVideosScreen(),
                    ),
                  );
                },
                tooltip: 'Collections',
              ),
            ),
          ),
          // Centered upload button
          ElevatedButton(
            onPressed: () {
              // TODO: Implement upload functionality.
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          // Profile button on the right
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                tooltip: 'Profile',
              ),
            ),
          ),
        ],
      ),
    );
  }
} 