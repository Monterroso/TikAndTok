Overview of the Video Collections Feature

What Are We Trying to Accomplish?
Our goal is to implement a robust feature that allows users to manage their video interactions in two separate ways:
Liking a video: Signifies positive engagement (a "heart" action).
Saving a video: Acts as a bookmarking function for later viewing (a "bookmark" action).
A video can be either liked, saved, both, or neither. We want to provide a clear, responsive user experience so that users can quickly interact with videos, and later review them from a dedicated page.

Implementation Decisions & Clarifications:
1. Data Structure: ✓
   - Store liked and saved videos as subcollections under user documents:
     - users/{userId}/liked_videos
     - users/{userId}/saved_videos
   - Add savedBy Set<String> to Video model, similar to likedBy
   - Keep category and tags within the metadata field for flexibility

2. UI/UX Decisions: ✓
   - Add new icon to CustomBottomNavigationBar for collections
   - Create separate tabs for liked and saved videos within collections view
   - Follow TikTok's placement for navigation items
   - ✓ Reuse and refactor LikeAnimation to InteractionAnimation for both like/save:
     - ✓ Support different icons (heart/bookmark)
     - ✓ Configurable active colors (red for likes, gold for saves)
     - ✓ Optional count display
     - ✓ Maintain existing animation pattern

3. Implementation Approach: ✓
   - ✓ Use optimistic updates for both likes and saves
   - ✓ Implement placeholder thumbnails initially (TODO: proper thumbnail generation)
   - ✓ No batch operations for now to maintain simplicity
   - ✓ Follow existing patterns for error handling and loading states

4. Performance Considerations: ✓
   - ✓ Focus on functionality in low-stress environments initially
   - ✓ Optimize for performance in future iterations

Why Are We Doing This?
Separation of Concerns: ✓
By keeping liked and saved videos in separate collections (subcollections under a user document), we gain flexibility. This clear separation makes it easier to extend functionality in the future (such as filtering by content categories or adding more metadata).
Robustness and Future-Proofing: ✓
Although our initial usage might be low, using subcollections is a more scalable solution. We also plan to integrate additional features like filtering and search, so a modular architecture (with a dedicated VideoCollectionManager) will allow us to reuse and extend functionality as needed.
Enhanced User Experience: ✓
Thumbnail Generation: Thumbnails provide a visual snapshot of each video, making our UI more appealing and allowing users to quickly identify content.
UI Feedback: Proper animations, visual states, and notifications (snackbars) will ensure that users know when their interactions (like/save) are occurring successfully.
Real-Time Updates: Leveraging Firestore streams and our Provider setup means updates to liked or saved videos show up immediately in the UI.
4. Maintainability: ✓
By breaking down the feature into small, testable modules (data layer, thumbnail generator, state manager, UI components), we adhere to our team's coding standards and ensure that each component can be individually maintained and enhanced in the future.
---
Detailed Implementation Checklist
Below is a step-by-step checklist for implementing the feature. Each step includes not only the development tasks but also context on why those tasks are important.
---
Step 1: Data Model & Firestore Service Setup ✓
Objective:
Create robust data models and Firestore service methods to manage the liked and saved videos subcollections. This ensures that the data layer is scalable, maintainable, and can be easily accessed by other parts of the app.

1.1. Define Subcollections in Firestore ✓
[✓] Task: Decide on the following subcollection paths under the user document:
users/{userId}/liked_videos
users/{userId}/saved_videos
Why: Using subcollections provides a more scalable solution than embedding arrays in the user document. It will better support future growth and additional metadata for each video.

1.2. Update Video Model ✓
[✓] Add savedBy Set<String> to Video model
[✓] Add helper methods (isSavedByUser, saveCount)
[✓] Update fromFirestore and toFirestore methods
[✓] Add any necessary validation

1.3. Update Firestore Service ✓
File: lib/services/firestore_service.dart
[✓] Add Method: Future<void> addLikedVideo({required String userId, required String videoId})
   - Ensure it writes a new document in users/{userId}/liked_videos
   - Add error handling and logging
[✓] Add Method: Future<void> removeLikedVideo({required String userId, required String videoId})
   - Ensure it deletes the corresponding document
   - Handle cases where the document does not exist
[✓] Add Method: Future<void> addSavedVideo({required String userId, required String videoId})
   - Write a new document in users/{userId}/saved_videos
   - Ensure error handling is in place
[✓] Add Method: Future<void> removeSavedVideo({required String userId, required String videoId})
   - Delete the document from users/{userId}/saved_videos
   - Validate proper deletion with error handling
[✓] Add Method: Stream<List<Video>> streamLikedVideos({required String userId})
   - Create a stream listener for changes in the liked videos subcollection
   - Convert Firestore documents to Video model instances
[✓] Add Method: Stream<List<Video>> streamSavedVideos({required String userId})
   - Create a stream listener for the saved videos subcollection
   - Convert documents to Video instances

1.4. Documentation & Comments ✓
[✓] Add clear comments for each new method
[✓] Update relevant development documentation

1.5. Testing ✓
[✓] Write unit tests for Video model changes
[✓] Write unit tests for Firestore service methods using mock Firestore data
[✓] Test error handling and edge cases

---
Step 2: Develop the VideoCollectionManager ✓
Objective:
Create a centralized manager (or controller) to handle video collection operations. This includes fetching data (liked and saved videos), filtering, and searching—all while providing real-time updates via state management.

2.1. Create Manager Class ✓
File: lib/controllers/video_collection_manager.dart
[✓] Class: VideoCollectionManager
[✓] Extend ChangeNotifier to integrate with Provider.
Why: Centralizing collection logic ensures consistency and reusability. The manager acts as the single point of truth for video collections.

2.2. Define State Variables ✓
[✓] Define properties:
List<Video> likedVideos = [];
List<Video> savedVideos = [];
Map<String, dynamic> metadata; (for categories, tags, etc.)
Why: Tracking these states enables the UI to react to changes immediately and supports future extensions like filtering and search.

2.3. Implement Fetching Methods ✓
[✓] Method: Future<void> fetchLikedVideos(String userId)
[✓] Use the Firestore service's streamLikedVideos.
[✓] Update likedVideos and call notifyListeners().
[✓] Method: Future<void> fetchSavedVideos(String userId)
[✓] Use streamSavedVideos.
[✓] Update savedVideos and notify listeners.
Why: These methods ensure the VideoCollectionManager fetches data in real time and updates the UI accordingly.

2.4. Implement Filtering & Searching ✓
[✓] Method: List<Video> filterVideosByCategory(String category)
[✓] Filter the videos by the category field within the Video model.
[✓] Method: List<Video> searchVideos(String query)
[✓] Search the videos based on title, tags, or additional metadata.
Why: Even though filtering/search might be a future feature, building the hooks now makes it easier to extend the manager without a major refactor later.

2.5. Provider Integration ✓
[✓] Register VideoCollectionManager using Provider in the main widget tree.
Why: Provider allows our UI components to listen for state changes and react in real time, streamlining the overall data flow.

2.6. Testing ✓
[✓] Write unit tests for state updates and action methods.
[✓] Verify that notifyListeners() triggers proper UI refresh.
Why: Ensuring the manager works as intended is vital for a reactive and stable UI.

---
Step 3: UI Components Refactoring ✓
Objective:
Refactor existing UI components to support both like and save interactions with consistent behavior.

3.1. Refactor LikeAnimation ✓
[✓] Rename to InteractionAnimation
[✓] Add parameters for icon and color
[✓] Make count display optional
[✓] Update existing usages in RightActionsColumn
[✓] Test animation behavior for both like and save

3.2. Update RightActionsColumn ✓
[✓] Modify save button to use InteractionAnimation
[✓] Add save interaction handling
[✓] Ensure proper state management for both actions

---
Step 4: UI Integration on the Video Feed ✓
Objective:
Enhance the video feed interface by adding buttons for liking and saving videos. The UI must offer intuitive visual feedback and connect user interactions with the underlying data services.

4.1. Enhance Video Card UI ✓
[✓] Add two buttons/icons:
   - Like Button: (heart icon; shows filled vs. outline state)
   - Save Button: (bookmark icon)

4.2. Connect Buttons to Functionality ✓
[✓] On tap of the like button:
   - Call Firestore service through VideoCollectionManager
   - Update liked_videos subcollection
[✓] On tap of the save button:
   - Call corresponding Firestore method for saved_videos
   - Update user's saved_videos collection
[✓] Display visual feedback (animations/snackbars) upon interaction
[✓] Implement optimistic updates for immediate UI feedback
[✓] Add error handling with user-friendly messages
[✓] Ensure proper state management for concurrent updates

4.3. Testing ✓
[✓] Write widget tests that simulate button taps and verify UI state
[✓] Use mock Firestore services to verify correct method calls

---
Step 5: Create the Saved Videos Screen UI ✓
Objective:
Develop a dedicated screen for displaying the user's liked and saved videos. This screen should clearly separate the two collections and provide options for further interaction (such as removal).

5.1. Set Up the Screen ✓
File: lib/screens/saved_videos_screen.dart
[✓] Create a basic scaffold with an AppBar.
[✓] Design the layout to display two sections (or use tabs) for:
   - Liked Videos
   - Saved Videos

5.2. Implement Data Streaming ✓
[✓] Use StreamBuilder or a Consumer<VideoCollectionManager> to listen for real-time updates.
[✓] Bind each section to the corresponding video list from the manager.

5.3. Display Video Details ✓
[✓] Create reusable VideoGrid component for consistent display
[✓] Include video metadata (e.g., title) beneath each thumbnail
[✓] Implement placeholder thumbnails (proper thumbnail generation deferred)

5.4. Interaction and Removal ✓
[✓] Provide an option (e.g., an "X" icon) on each video card to allow removal from the collection.
[✓] Connect the removal control to the corresponding Firestore service call.

5.5. Testing ✓
[✓] Write widget tests to verify:
   - Tab rendering and navigation
   - Video display in both liked and saved tabs
   - Loading states
   - Error handling
   - Empty states
   - Remove functionality in both tabs
[✓] Implement comprehensive test coverage with mock providers

---
Step 6: Navigation Integration ✓
Objective:
Integrate the new Saved Videos screen into our app's navigation structure so that users can easily switch between their video feed and collection views.

6.1. Update Navigation Components ✓
File: lib/widgets/video_viewing/custom_bottom_navigation_bar.dart
[✓] Add a new navigation button/icon specifically for the Saved Videos screen.
   - Added collections_bookmark icon on the left side
   - Improved layout with proper spacing
   - Added tooltips for better accessibility
[✓] Ensure that this button is visually distinct.
   - Used standard collections_bookmark icon
   - Maintained consistent styling with other navigation items
   - Added proper padding and alignment

6.2. Routing ✓
[✓] Update navigation to include route for SavedVideosScreen.
[✓] Implement proper screen transitions.
Why: Proper routing ensures a seamless navigation experience throughout the app.

6.3. Testing ✓
[✓] Write widget tests to verify:
   - Button rendering
   - Navigation transitions
   - Visual styling
   - Tooltip accessibility
[✓] Perform manual testing to ensure smooth transitions.

---
Step 7: Final Testing, Integration, & Documentation ✓
Objective:
Ensure all parts of the feature are integrated, free of regressions, and well-documented. This step is critical to maintain consistency and long-term maintainability.

7.1. Unit Tests ✓
[✓] Write unit tests for:
Firestore service methods.
VideoCollectionManager's state updates and filtering/search methods.
Why: Unit tests catch issues early and ensure each module behaves as expected.

7.2. Widget & Integration Tests ✓
[✓] Write tests to verify that the UI components (video cards, saved videos screen) interact correctly with the provider.
Why: Integration tests ensure that all modules work together seamlessly.

7.3. Peer Review & Code Quality Checks ✓
[✓] Run linters and verify adherence to our coding style guides.
[✓] Conduct code reviews to ensure consistency with our development_guidelines.md and architecture.md.
Why: Code reviews and linting maintain the quality and consistency of the codebase.

7.4. Documentation Updates ✓
[✓] Update documentation to reflect the new Firestore subcollections.
[✓] Document the VideoCollectionManager's API and integration points.
[✓] Add comments and a readme section regarding the thumbnail generation approach.
Why: Up-to-date documentation is critical to onboard new team members and ensure long-term maintainability.

---
Step 8: Thumbnail Generation Module (Deferred)
Objective:
Develop a thumbnail generation module to create visual representations of videos. Thumbnails are key for a quick, at-a-glance understanding of video content and improve user experience on video listing pages.

This step has been deferred to a future iteration to focus on core functionality first. The current implementation uses placeholder thumbnails with gradients and play icons.

---
Final Implementation Notes:

1. Architecture Overview:
   - VideoCollectionManager serves as the central state management solution
   - Firestore subcollections provide scalable data storage
   - Provider pattern enables real-time UI updates
   - Clean separation of concerns between data, business logic, and UI layers

2. Performance Optimizations:
   - Optimistic updates for immediate UI feedback
   - Efficient state management through Provider
   - Lazy loading of video data
   - Placeholder thumbnails to reduce initial load time

3. Future Enhancements:
   - Implement proper thumbnail generation
   - Add batch operations for bulk actions
   - Enhance search and filtering capabilities
   - Add video categories and tags
   - Implement video recommendations based on likes

4. Known Limitations:
   - Placeholder thumbnails instead of actual video previews
   - Basic search functionality
   - Limited metadata support
   - No batch operations

5. Testing Coverage:
   - Unit tests for all core functionality
   - Widget tests for UI components
   - Integration tests for key user flows
   - Mock providers for isolated testing

This implementation provides a solid foundation for future enhancements while maintaining clean architecture and following best practices for Flutter development.