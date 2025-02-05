Step 1. Define Requirements and Prepare Your Environment
Review Requirements & Reference Docs:
Feature Inventory: Confirm the sub-tasks for Core Video Feed & Playback (see feature_inventory.md).
Flutter iOS: Verify system and hardware requirements (see Flutter_ios).
Firebase: If video metadata or URLs are fetched from the backend, review Firebase Firestore/Storage guidelines 1.
Confirm Dependencies:
Ensure your pubspec.yaml includes necessary packages such as:
`video_player` for video playback.
`provider` if managing state with Provider.
Run:
get
---
Step 2. Create or Update the Video Viewing Screen
File Creation:
Check if lib/screens/video_viewing_screen.dart exists. If not, create it.
Setup a Base Scaffold:
Import the required UI components (many of which we already defined under lib/widgets/video_viewing/).
Example Code Skeleton:
}
---
Step 3. Implement the Video Background
Since our videos are the central focus, we need a background widget capable of playing videos (e.g., a looping video). We may later use this inside a swipeable feed.
Create VideoBackground Widget:
File: lib/widgets/video_viewing/video_background.dart
Responsibilities:
Load a video (from assets, network, or Firebase Storage).
Auto-play and loop the video.
Manage the video controller lifecycle.
Example Code:
}
---
Step 4. Create a Swipeable Video Feed
Enable users to swipe between videos vertically by implementing a PageView.
Create VideoFeed Widget:
File: lib/widgets/video_viewing/video_feed.dart
Responsibilities:
Wrap video items in a PageView oriented vertically.
Allow each page to load a video (using a dedicated video player widget).
Example Code:
}
---
Step 5. (Optional) Integrate Firebase for Dynamic Video Data
If your application fetches video URLs or metadata from Firebase:
Firestore Integration:
Create a query method (within your FirestoreService) to retrieve video information.
Use a StreamBuilder or state management solution (e.g., Provider) to supply video data to the VideoFeed widget.
Storage Considerations:
If videos are stored in Firebase Storage, make sure you have proper access and caching strategies.
---
Step 6. Integrate Overlaid UI Elements
Reuse and/or create overlay widgets for:
TopSearchButton: For searching.
RightActionsColumn: For like, comment, share buttons.
CreatorInfoGroup: For displaying video creator information.
CustomBottomNavigationBar: For app navigation.
These components are already defined in the lib/widgets/video_viewing/ folder. Verify they import correctly and are positioned with Positioned widgets, as shown in the VideoViewingScreen example.
---
Step 7. Assemble and Test the Video Viewing Screen
Compose the UI:
Replace the static VideoBackground in your screen with the swipeable VideoFeed component.
Maintain the overlay UI elements from Step 2.
Test on a Device/Simulator:
Run the app on an iOS simulator (see Flutter iOS guide) to confirm smooth video playback and swipe transition.
Check responsiveness and auto-play functionality.
Validate that video transitions (swipes) do not trigger memory leaks (properly dispose of video controllers).
---
Step 8. Optimize Performance and Final Checks
Performance Improvements:
Use lazy loading in the PageView if the video list is large.
Ensure that each video controller is disposed of correctly.
Optimize asset sizes or use adaptive streaming if using network videos.
UI and Testing:
Review the visual layout and interactivity.
Test on multiple devices (especially iOS) to ensure a consistent experience.
Update documentation:
Mark the Core Video Feed & Playback feature in feature_inventory.md.
Update architecture documents if new modules or patterns are introduced.