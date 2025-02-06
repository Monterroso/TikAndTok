Overview of the Video Collections Feature

What Are We Trying to Accomplish?
Our goal is to implement a robust feature that allows users to manage their video interactions in two separate ways:
Liking a video: Signifies positive engagement (a "heart" action).
Saving a video: Acts as a bookmarking function for later viewing (a "bookmark" action).
A video can be either liked, saved, both, or neither. We want to provide a clear, responsive user experience so that users can quickly interact with videos, and later review them from a dedicated page.

Implementation Decisions & Clarifications:
1. Data Structure:
   - Store liked and saved videos as subcollections under user documents:
     - users/{userId}/liked_videos
     - users/{userId}/saved_videos
   - Add savedBy Set<String> to Video model, similar to likedBy
   - Keep category and tags within the metadata field for flexibility

2. UI/UX Decisions:
   - Add new icon to existing CustomBottomNavigationBar for collections
   - Create separate tabs for liked and saved videos within collections view
   - Follow TikTok's placement for navigation items
   - Reuse and refactor LikeAnimation to InteractionAnimation for both like/save:
     - Support different icons (heart/bookmark)
     - Configurable active colors (red for likes, gold for saves)
     - Optional count display
     - Maintain existing animation pattern

3. Implementation Approach:
   - Use optimistic updates for both likes and saves
   - Implement placeholder thumbnails initially (TODO: proper thumbnail generation)
   - No batch operations for now to maintain simplicity
   - Follow existing patterns for error handling and loading states

4. Performance Considerations:
   - Focus on functionality in low-stress environments initially
   - Optimize for performance in future iterations

Why Are We Doing This?
Separation of Concerns:
By keeping liked and saved videos in separate collections (subcollections under a user document), we gain flexibility. This clear separation makes it easier to extend functionality in the future (such as filtering by content categories or adding more metadata).
Robustness and Future-Proofing:
Although our initial usage might be low, using subcollections is a more scalable solution. We also plan to integrate additional features like filtering and search, so a modular architecture (with a dedicated VideoCollectionManager) will allow us to reuse and extend functionality as needed.
Enhanced User Experience:
Thumbnail Generation: Thumbnails provide a visual snapshot of each video, making our UI more appealing and allowing users to quickly identify content.
UI Feedback: Proper animations, visual states, and notifications (snackbars) will ensure that users know when their interactions (like/save) are occurring successfully.
Real-Time Updates: Leveraging Firestore streams and our Provider setup means updates to liked or saved videos show up immediately in the UI.
4. Maintainability:
By breaking down the feature into small, testable modules (data layer, thumbnail generator, state manager, UI components), we adhere to our team's coding standards and ensure that each component can be individually maintained and enhanced in the future.
---
Detailed Implementation Checklist
Below is a step-by-step checklist for implementing the feature. Each step includes not only the development tasks but also context on why those tasks are important.
---
Step 1: Data Model & Firestore Service Setup
Objective:
Create robust data models and Firestore service methods to manage the liked and saved videos subcollections. This ensures that the data layer is scalable, maintainable, and can be easily accessed by other parts of the app.

1.1. Define Subcollections in Firestore
[ ] Task: Decide on the following subcollection paths under the user document:
users/{userId}/liked_videos
users/{userId}/saved_videos
Why: Using subcollections provides a more scalable solution than embedding arrays in the user document. It will better support future growth and additional metadata for each video.

1.2. Update Video Model
[ ] Add savedBy Set<String> to Video model
[ ] Add helper methods (isSavedByUser, saveCount)
[ ] Update fromFirestore and toFirestore methods
[ ] Add any necessary validation

1.3. Update Firestore Service
File: lib/services/firestore_service.dart
[ ] Add Method: Future<void> addLikedVideo({required String userId, required String videoId})
   - Ensure it writes a new document in users/{userId}/liked_videos
   - Add error handling and logging
[ ] Add Method: Future<void> removeLikedVideo({required String userId, required String videoId})
   - Ensure it deletes the corresponding document
   - Handle cases where the document does not exist
[ ] Add Method: Future<void> addSavedVideo({required String userId, required String videoId})
   - Write a new document in users/{userId}/saved_videos
   - Ensure error handling is in place
[ ] Add Method: Future<void> removeSavedVideo({required String userId, required String videoId})
   - Delete the document from users/{userId}/saved_videos
   - Validate proper deletion with error handling
[ ] Add Method: Stream<List<Video>> streamLikedVideos({required String userId})
   - Create a stream listener for changes in the liked videos subcollection
   - Convert Firestore documents to Video model instances
[ ] Add Method: Stream<List<Video>> streamSavedVideos({required String userId})
   - Create a stream listener for the saved videos subcollection
   - Convert documents to Video instances

1.4. Documentation & Comments
[ ] Add clear comments for each new method
[ ] Update relevant development documentation
Why: Keeping documentation up-to-date ensures that team members understand the purpose behind each method and how to use them.

1.5. Testing
[ ] Write unit tests for Video model changes
[ ] Write unit tests for Firestore service methods using mock Firestore data
[ ] Test error handling and edge cases

---
Step 2: Develop the VideoCollectionManager
Objective:
Create a centralized manager (or controller) to handle video collection operations. This includes fetching data (liked and saved videos), filtering, and searching—all while providing real-time updates via state management.

2.1. Create Manager Class
File: lib/controllers/video_collection_manager.dart
[ ] Class: VideoCollectionManager
[ ] Extend ChangeNotifier to integrate with Provider.
Why: Centralizing collection logic ensures consistency and reusability. The manager acts as the single point of truth for video collections.

2.2. Define State Variables
[ ] Define properties:
List<Video> likedVideos = [];
List<Video> savedVideos = [];
Map<String, dynamic> metadata; (for categories, tags, etc.)
Why: Tracking these states enables the UI to react to changes immediately and supports future extensions like filtering and search.

2.3. Implement Fetching Methods
[ ] Method: Future<void> fetchLikedVideos(String userId)
[ ] Use the Firestore service's streamLikedVideos.
[ ] Update likedVideos and call notifyListeners().
[ ] Method: Future<void> fetchSavedVideos(String userId)
[ ] Use streamSavedVideos.
[ ] Update savedVideos and notify listeners.
Why: These methods ensure the VideoCollectionManager fetches data in real time and updates the UI accordingly.

2.4. Implement Filtering & Searching
[ ] Method: List<Video> filterVideosByCategory(String category)
[ ] Filter the videos by the category field within the Video model.
[ ] Method: List<Video> searchVideos(String query)
[ ] Search the videos based on title, tags, or additional metadata.
Why: Even though filtering/search might be a future feature, building the hooks now makes it easier to extend the manager without a major refactor later.

2.5. Provider Integration
[ ] Register VideoCollectionManager using Provider in the main widget tree.
Why: Provider allows our UI components to listen for state changes and react in real time, streamlining the overall data flow.

2.6. Testing
[ ] Write unit tests for state updates and action methods.
[ ] Verify that notifyListeners() triggers proper UI refresh.
Why: Ensuring the manager works as intended is vital for a reactive and stable UI.

---
Step 3: UI Components Refactoring
Objective:
Refactor existing UI components to support both like and save interactions with consistent behavior.

3.1. Refactor LikeAnimation
[ ] Rename to InteractionAnimation
[ ] Add parameters for icon and color
[ ] Make count display optional
[ ] Update existing usages in RightActionsColumn
[ ] Test animation behavior for both like and save

3.2. Update RightActionsColumn
[ ] Modify save button to use InteractionAnimation
[ ] Add save interaction handling
[ ] Ensure proper state management for both actions

---
Step 4: UI Integration on the Video Feed
Objective:
Enhance the video feed interface by adding buttons for liking and saving videos. The UI must offer intuitive visual feedback and connect user interactions with the underlying data services.

4.1. Enhance Video Card UI
File (Example): lib/widgets/video_viewing/video_card.dart
[ ] Add two buttons/icons:
Like Button: (heart icon; shows filled vs. outline state).
Save Button: (bookmark icon).
Why: These controls give users a quick and intuitive way to mark videos they enjoy or want to revisit.

4.2. Connect Buttons to Functionality
[ ] On tap of the like button:
[ ] Call the relevant Firestore service through the VideoCollectionManager to add/remove the video in the liked_videos subcollection.
[ ] On tap of the save button:
[ ] Call the corresponding Firestore method for the saved_videos subcollection.
[ ] Display visual feedback (animations/snackbars) upon interaction.
Why: Integration between the UI and backend is key to ensuring a responsive experience that reflects the user's actions immediately.

4.3. Testing
[ ] Write widget tests that simulate button taps and verify UI state.
[ ] Use mock Firestore services to verify correct method calls.
Why: Robust testing ensures that the interactions work across different scenarios and devices.

---
Step 5: Create the Saved Videos Screen UI
Objective:
Develop a dedicated screen for displaying the user's liked and saved videos. This screen should clearly separate the two collections and provide options for further interaction (such as removal).

5.1. Set Up the Screen
File: lib/screens/saved_videos_screen.dart
[ ] Create a basic scaffold with an AppBar.
[ ] Design the layout to display two sections (or use tabs) for:
Liked Videos
Saved Videos
Why: A dedicated screen makes it easier for users to manage and navigate through their collected videos.

5.2. Implement Data Streaming
[ ] Use StreamBuilder or a Consumer<VideoCollectionManager> to listen for real-time updates.
[ ] Bind each section to the corresponding video list from the manager.
Why: Keeping the screen in sync with live data ensures that any changes (like removals) are reflected immediately.

5.3. Display Thumbnails and Video Details
[ ] Utilize the previously built ThumbnailWidget to show video thumbnails.
[ ] Include video metadata (e.g., title, category) beneath each thumbnail.
Why: Visual cues and metadata enhance the overall user experience by providing context at a glance.

5.4. Interaction and Removal
[ ] Provide an option (e.g., an "X" icon) on each video card to allow removal from the collection.
[ ] Connect the removal control to the corresponding Firestore service call.
Why: Allowing removal ensures users can manage their collections effectively.

5.5. Testing
[ ] Write widget tests to verify correct display and removal interactions.
Why: These tests confirm both the correctness and responsiveness of the UI.

---
Step 6: Navigation Integration
Objective:
Integrate the new Saved Videos screen into our app's navigation structure so that users can easily switch between their video feed and collection views.

6.1. Update Navigation Components
File: lib/widgets/video_viewing/custom_bottom_navigation_bar.dart
[ ] Add a new navigation button/icon specifically for the Saved Videos screen.
[ ] Ensure that this button is visually distinct.
Why: A well-designed navigation bar promotes discoverability and ease-of-use for new features.

6.2. Routing
[ ] Update the Navigator configuration (or AutoRoute settings) to include a route for SavedVideosScreen.
[ ] Validate that tapping the navigation button switches screens correctly.
Why: Proper routing is essential for a seamless navigation experience throughout the app.

6.3. Testing
[ ] Write integration tests to verify navigation transitions.
[ ] Perform manual testing on a device/emulator to ensure smooth transitions.
Why: Ensuring reliable navigation maintains overall app usability and helps catch potential routing errors.

---
Step 7: Final Testing, Integration, & Documentation
Objective:
Ensure all parts of the feature are integrated, free of regressions, and well-documented. This step is critical to maintain consistency and long-term maintainability.

7.1. Unit Tests
[ ] Write unit tests for:
Firestore service methods.
Thumbnail generation utility.
VideoCollectionManager's state updates and filtering/search methods.
Why: Unit tests catch issues early and ensure each module behaves as expected.

7.2. Widget & Integration Tests
[ ] Write tests to verify that the UI components (video cards, saved videos screen) interact correctly with the provider.
Why: Integration tests ensure that all modules work together seamlessly.

7.3. Peer Review & Code Quality Checks
[ ] Run linters and verify adherence to our coding style guides.
[ ] Conduct code reviews to ensure consistency with our development_guidelines.md and architecture.md.
Why: Code reviews and linting maintain the quality and consistency of the codebase.

7.4. Documentation Updates
[ ] Update documentation to reflect the new Firestore subcollections.
[ ] Document the VideoCollectionManager's API and integration points.
[ ] Add comments and a readme section regarding the thumbnail generation approach.
Why: Up-to-date documentation is critical to onboard new team members and ensure long-term maintainability.

---
Step 8: Thumbnail Generation Module
Objective:
Develop a thumbnail generation module to create visual representations of videos. Thumbnails are key for a quick, at-a-glance understanding of video content and improve user experience on video listing pages.

2.1. Add Dependency
[ ] Edit pubspec.yaml to include the `video_thumbnail` package.
[ ] Run flutter pub get to fetch the package.
Why: The package provides an out-of-the-box solution to generate thumbnails from video files, reducing development time.

2.2. Create Thumbnail Utility
File: lib/utils/thumbnail_generator.dart
[ ] Function: Future<File> generateThumbnail(String videoPath)
[ ] Use the API from video_thumbnail to generate a thumbnail.
[ ] Implement error handling: return a default thumbnail if generation fails.
[ ] Test this function with various video paths.
Why: This utility centralizes thumbnail generation, so if we ever need to switch strategies (e.g., to a third-party API like Cloudinary), we only have to update this module.

2.3. (Optional) Create a Reusable Thumbnail Widget
File: lib/widgets/thumbnail_widget.dart
[ ] Widget: ThumbnailWidget
[ ] Accepts a video path or URL.
[ ] Displays a loading indicator while generating the thumbnail.
[ ] Shows the generated thumbnail image.
[ ] Gracefully handles failures by displaying a fallback image.
Why: Providing a reusable widget makes it simple to display thumbnails consistently across different screens.

2.4. Testing
[ ] Write unit tests for the thumbnail utility.
[ ] Verify visual correctness across devices.
Why: Testing ensures reliability of the thumbnail generation, which is critical for a seamless user experience.

Final Considerations
Thumbnail Generation Module First?
While the VideoCollectionManager is central, starting with the thumbnail generation module is advisable. This ensures that when the manager fetches video data, the UI components can immediately display thumbnails. We either complete the thumbnail module first or work on both in parallel, ensuring that tests exist to validate their proper functionality.

Modular and Testable Approach:
Breaking down this massive feature into discrete, testable parts helps maintain clarity, reduces risk, and allows us to build a feature incrementally. Each task is designed to be simple and maintainable—aligning with our clean coding standards and architecture guidelines.

By following this detailed plan and understanding the context behind each step, anyone joining the project or reviewing the code will have a clear picture of what we aim to achieve and why each component is critical for the overall feature integrity.

Let me know if you have any questions or need further clarifications on any part of the plan!