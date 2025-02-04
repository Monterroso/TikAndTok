import 'package:flutter/material.dart';

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