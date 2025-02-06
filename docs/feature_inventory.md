# Feature Inventory for D&D TikTok Clone

This document tracks all implemented and planned features for the application. It lists features by priority (Must-Have, Should-Have, Could-Have) with detailed locations and sub-tasks. This inventory acts as the single source of truth on what exists and what each feature does.

## Must-Have Features

- [✓] **User Authentication & Profile Management**  
  *Description:* Enable users to securely register, log in, and manage their profiles using Firebase Authentication.  
  **Sub-Tasks:**
  - [✓] Implement sign-up (email/password and/or social logins)  
    *Location:* `lib/services/auth_service.dart`  
  - [✓] Implement login and logout flows  
    *Location:* `lib/screens/login_screen.dart`
  - [✓] Ensure session persistence and error handling  
    *Location:* `lib/screens/login_screen.dart`
  - [✓] Automatic user profile creation on signup
    *Location:* `functions/src/index.ts`
    - Implemented and deployed Cloud Function
    - Creates Firestore document with default fields:
      - email (from Auth)
      - username (derived from display name)
      - bio (empty string)
      - photoURL (from Auth or empty)
      - createdAt & updatedAt timestamps
    - Handles data consistency between Auth and Firestore
    - Includes error handling and logging
  - [✓] Create a basic user profile screen for viewing/updating profile info  
    *Location:* `lib/screens/profile_screen.dart`
    - Implemented profile screen with:
      - Profile picture upload (camera/gallery)
      - Username field with validation
      - Bio field with character limit
      - Update profile button with loading state
      - Logout functionality in AppBar
      - Error handling and user feedback
    - Added navigation from bottom bar profile icon
    *Location:* `lib/widgets/video_viewing/custom_bottom_navigation_bar.dart`

- [✓] **Core Video Feed & Playback**  
  *Description:* Provide a seamless, scrollable video feed with integrated creator profiles as the primary interface for content discovery.  
  **Sub-Tasks:**
  - [✓] Design and implement video feed UI  
    *Location:* `lib/screens/video_viewing_screen.dart`, `lib/widgets/video_viewing/video_feed.dart`
    - Implemented vertical swipeable video feed
    - Added smooth video transitions
    - Added debug information for development
    - Integrated creator profile display
      - Profile picture with fallback
      - Username/display name
      - Video title and description
  - [✓] Implement video playback  
    *Location:* `lib/widgets/video_viewing/video_background.dart`
    - Added video player with auto-play and looping
    - Implemented error handling for invalid videos
    - Added loading states and error messages
  - [✓] Set up video data model and integration
    *Location:* `lib/models/video.dart`, `lib/widgets/video_viewing/creator_info_group.dart`
    - Created Video model with Firestore integration
    - Added URL validation
    - Implemented error handling for required fields
    - Real-time profile data streaming
    - Loading states with skeleton UI
    - Error states with user feedback
    - User existence verification
  - [✓] System Integration
    - Uses Firebase Storage for video URLs
    - Uses Firestore for video metadata
    - Integrates with user profiles
    - Proper error handling and validation

  *Note: Core video playback, feed functionality, and profile integration are complete. Interactive features (likes, comments, etc.) will be implemented in the next phase.*

- [✓] **Basic Video Interaction (Like & Comment)**  
  *Description:* Enable users to interact with videos by liking and commenting.  
  **Sub-Tasks:**
  - [✓] Implement the like functionality with real-time UI updates  
    *Location:* 
    - `lib/widgets/video_viewing/like_animation.dart` - Heart animation and UI
    - `lib/services/firestore_service.dart` - Like data management
    - `lib/models/video.dart` - Like data model
    Features implemented:
    - Double-tap anywhere to toggle like status
    - Heart button in right column
    - Heart animation at tap location
    - Optimistic updates for responsive UI
    - Real-time Firestore integration
    - Error handling with user feedback
    - Haptic feedback on interactions
  - [✓] Create and integrate a basic comment interface with Firestore support  
    *Location:* 
    - `lib/widgets/video_viewing/comments/comments_sheet.dart` - Modal bottom sheet
    - `lib/widgets/video_viewing/comments/comment_list.dart` - Scrollable comment list
    - `lib/widgets/video_viewing/comments/comment_tile.dart` - Individual comment display
    - `lib/widgets/video_viewing/comments/comment_input.dart` - Comment input field
    Features implemented:
    - Real-time comment updates
    - Comment count tracking
    - User profile integration
    - Delete own comments
    - Newest comments first
    - Error handling and loading states
    - Proper UI alignment for own/other comments
  - [✓] Ensure immediate feedback (e.g., icon animations) during interactions
    *Location:* 
    - `lib/widgets/video_viewing/like_animation.dart`
    - `lib/screens/video_viewing_screen.dart`

- [ ] **Viewing & Managing Saved Videos**  
  *Description:* Allow users to bookmark and manage their favorite videos for quick retrieval later.  
  **Sub-Tasks:**
  - [ ] Create a dedicated UI section for saved videos  
    *Location:* `lib/screens/saved_videos_screen.dart`
  - [ ] Implement functionality to add, remove, or update saved items (sync with Firestore)

## Should-Have Features

- [ ] **Filtering Videos by D&D Categories**  
  *Description:* Allow users to narrow down the video feed by specific content categories related to tabletop RPGs.  
  **Sub-Tasks:**
  - [ ] Define and implement the following categories and tags:
    - Campaign Chronicles  
    - DM Tips & Tricks  
    - Player Highlights  
    - Dice & Mechanics  
    - DIY & Homebrew  
    - Cosplay & Fan Art  
  - [ ] Attach metadata/tags to videos in `lib/models/video.dart`
  - [ ] Build a filtering UI that queries Firestore based on selected tags  
    *Location:* `lib/screens/filter_screen.dart`

- [ ] **Saving/Bookmarking Video Content**  
  *Description:* Let users bookmark their favorite videos for inspiration and future reference.  
  **Sub-Tasks:**
  - [ ] Develop a bookmarking feature through a "Save" button on video cards  
    *Location:* `lib/widgets/video_card.dart`
  - [ ] Persist saved items in the user's profile collection in Firestore

- [ ] **Collection Creation for Saved Content**  
  *Description:* Permit users to organize saved videos into manageable, custom collections.  
  **Sub-Tasks:**
  - [ ] Build a UI flow for creating, editing, and deleting collections  
    *Location:* `lib/screens/collections_screen.dart`
  - [ ] Implement drag-and-drop functionality or tagging to add videos into collections  
  - [ ] Synchronize collections data with Firestore

## Could-Have Features

- [ ] **Advanced Content Recommendations**  
  *Description:* Offer personalized video suggestions based on the user's viewing history and interactions.  
  **Sub-Tasks:**
  - [ ] Develop a recommendation algorithm citing historical data
  - [ ] Integrate recommendations into the home feed dynamically

- [ ] **Enhanced Community Engagement**  
  *Description:* Deepen community interactions by offering features such as threaded discussions, additional reaction options, and content sharing across social platforms.  
  **Sub-Tasks:**
  - [ ] Implement threaded comments on videos  
    *Location:* `lib/screens/video_details_screen.dart`
  - [ ] Offer additional reaction emojis or icons  
  - [ ] Integrate functionality that allows sharing posts externally

- [ ] **Analytics & Trending Content**  
  *Description:* Provide insights into trending topics and content performance to help users discover popular or emerging trends.  
  **Sub-Tasks:**
  - [ ] Build a dashboard for displaying trending tags and popular videos  
  - [ ] Analyze user engagement data to power trends and recommendations  
  - [ ] Display simple analytics summaries for video performance

- [ ] **Upcoming Features and Optimizations**
  - [ ] Video creator data prefetching
  - [ ] Profile data caching
  - [ ] Follow functionality
  - [ ] Video interaction (likes, comments)
  - [ ] Performance optimizations

--- 