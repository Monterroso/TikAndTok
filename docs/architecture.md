# Application Architecture Overview

This document outlines the overall structure and design of our D&D TikTok clone application. It is intended to provide a clear view of the project organization, the responsibilities of each component, and the architectural patterns we follow. This overview will help everyone—developers and AI assistants alike—understand how the project is organized.

## Project Purpose

Our D&D TikTok clone is a Flutter application using Firebase as its backend. It centers on the consumer journey for tabletop roleplaying game enthusiasts. The app allows users to browse, watch, and interact with videos related to Dungeons & Dragons and other tabletop RPGs.

## Directory Structure

Below is a visual breakdown of the project directories and key files. This structure promotes modularity, reusability, and clear separation of concerns: 

TikAndTok/
├── android/ // Native Android code & configuration
├── ios/ // Native iOS code & configuration (includes GoogleService-Info.plist)
├── lib/
│ ├── models/ // Data models for the application
│ │ ├── user.dart // (TODO) User model for authentication and profile information
│ │ ├── video.dart // Video model with VideoState, Firestore conversion, and URL validation
│ │ ├── comment.dart // Comment model for video interactions
│ │ └── collection.dart // (Planned) User-defined collections for bookmarked or grouped videos
│ ├── state/ // State management and caching layer
│ │ ├── video_state.dart // Immutable video state representation
│ │ │ └── VideoState // Core state class
│ │ │   ├── Properties // videoId, isLiked, isSaved, etc.
│ │ │   ├── Factory constructors // loading, error states
│ │ │   └── State management // copyWith, equality, etc.
│ │ ├── video_state_cache.dart // LRU cache implementation
│ │ │ └── VideoStateCache // Memory cache manager
│ │ │   ├── Cache operations // get, put, remove
│ │ │   ├── LRU implementation // eviction policy
│ │ │   └── Cleanup // stale data management
│ │ └── video_state_storage.dart // Persistent storage layer
│ │   └── VideoStateStorage // Local storage manager
│ │     ├── Storage operations // save, load, remove
│ │     ├── Data migration // version handling
│ │     └── Cleanup // old data removal
│ ├── screens/ // Entire UI pages of the application
│ │ ├── login_screen.dart // Handles user authentication (login/sign-up)
│ │ ├── home_screen.dart // (Deprecated) Previous home screen, replaced by video_viewing_screen
│ │ ├── video_viewing_screen.dart // Main video viewing screen with FrontPage widget
│ │ │ └── FrontPage // Core widget managing video feed and UI layout
│ │ │   ├── StreamBuilder<List<Video>> // Real-time video data from Firestore
│ │ │   ├── VideoCollectionManager Integration // Manages video states and interactions
│ │ │   └── UI Components // Positioned overlay elements
│ │ ├── profile_screen.dart // User profile management screen with image upload
│ │ ├── saved_videos_screen.dart // Displays liked and saved videos in a tabbed interface
│ │ ├── filter_screen.dart // (Planned) Allows filtering of videos by various criteria
│ │ └── collections_screen.dart // (Planned) UI for managing user-created collections
│ ├── controllers/ // Business logic and state coordination
│ │ └── video_collection_manager.dart // Manages video collections and interactions
│ │   └── VideoCollectionManager // Central state coordinator
│ │     ├── State management // cache and storage coordination
│ │     ├── Optimistic updates // immediate UI feedback
│ │     ├── Background operations // server updates
│ │     └── Error recovery // state reconciliation
│ ├── services/ // Service layer handling business logic and Firebase interactions
│ │ ├── auth_service.dart // Authentication operations
│ │ ├── firestore_service.dart // CRUD operations for Cloud Firestore
│ │ │ └── Video Operations // Methods for video data management
│ │ │   ├── streamVideos() // Real-time video feed with pagination
│ │ │   ├── getNextVideos() // Fetch next batch of videos
│ │ │   ├── createVideo() // Add new video document
│ │ │   ├── updateVideoStats() // Update video metrics
│ │ │   ├── toggleLike() // Toggle video like status
│ │ │   ├── toggleSave() // Toggle video save status
│ │ │   └── getVideoCollections() // Fetch user's video collections
│ │ ├── firebase_storage_service.dart // Manages video uploads and downloads
│ │ └── messaging_service.dart // (Planned) Handles push notifications
│ ├── widgets/ // Reusable UI components across the app
│ │ ├── video_viewing/ // Video viewing screen components
│ │ │ ├── video_background.dart // Video playback with error handling
│ │ │ │ └── VideoBackground // Manages video player lifecycle
│ │ │   ├── Auto-play and looping
│ │ │   ├── Error states with messages
│ │ │   └── Loading indicators
│ │ │ ├── video_feed.dart // Vertical swipeable video list
│ │ │ │ └── VideoFeed // Manages multiple videos
│ │ │   ├── PageView.builder for smooth scrolling
│ │ │   └── Video URL validation
│ │ │ ├── video_grid.dart // Grid display for saved/liked videos
│ │ │ │ └── VideoGrid // Reusable grid component
│ │ │   ├── Responsive layout with fixed aspect ratio
│ │ │   ├── Loading states with shimmer effect
│ │ │   ├── Error handling with retry
│ │ │   └── Empty state messaging
│ │ │ ├── comments/ // Comment-related components
│ │ │ │ ├── comments_sheet.dart // Modal bottom sheet for comments
│ │ │ │ │ └── CommentsSheet // Container for comment interface
│ │ │ │ │   ├── Real-time comment count updates
│ │ │ │ │   ├── Comment list integration
│ │ │ │ │   └── Comment input field
│ │ │ │ ├── comment_list.dart // Scrollable list of comments
│ │ │ │ │ └── CommentList // Manages comment display
│ │ │ │ │   ├── Real-time comment streaming
│ │ │ │ │   ├── Newest-first ordering
│ │ │ │ │   └── Delete functionality
│ │ │ │ ├── comment_tile.dart // Individual comment display
│ │ │ │ │ └── CommentTile // Single comment UI
│ │ │ │ │   ├── User profile integration
│ │ │ │ │   ├── Dynamic alignment
│ │ │ │ │   └── Delete option
│ │ │ │ └── comment_input.dart // Comment input field
│ │ │ │   └── CommentInput // New comment creation
│ │ │ │     ├── Input validation
│ │ │ │     ├── Loading states
│ │ │ │     └── Error handling
│ │ │ ├── creator_info_group.dart // Creator information display
│ │ │ ├── right_actions_column.dart // Action buttons UI
│ │ │ │ └── RightActionsColumn // Interactive buttons
│ │ │ │   ├── Like button with animation
│ │ │ │   ├── Save button with animation
│ │ │ │   ├── Comment button with count
│ │ │ │   └── Other action buttons
│ │ │ ├── interaction_animation.dart // Like/Save animations
│ │ │ │ └── InteractionAnimation // Unified animation component
│ │ │ │   ├── Configurable icons and colors
│ │ │ │   ├── Scale animation with sequence
│ │ │ │   ├── Haptic feedback
│ │ │ │   ├── Optional count display
│ │ │ │   └── State management
│ │ │ ├── custom_bottom_navigation_bar.dart // Basic navigation
│ │ │ └── top_search_button.dart // Search functionality
│ │ ├── auth/ // Authentication-related widgets
│ │ │ ├── auth_form.dart // Authentication form with validation
│ │ │ ├── auth_buttons.dart // Sign-in, sign-up, and Google auth buttons
│ │ │ ├── auth_fields.dart // Email and password input fields with validation
│ │ │ └── auth_snackbars.dart // Authentication feedback messages
│ │ ├── email_verification_banner.dart // Email verification prompt and resend
│ │ ├── profile_card.dart // User profile display with image
│ │ ├── video_card.dart // (Planned) Reusable video card component
│ │ ├── common_button.dart // (Planned) Common button styles
│ │ └── video_interaction.dart // (Planned) Common video interaction components
│ ├── firebase_options.dart // Firebase configuration
│ └── main.dart // Application entry point with Firebase initialization
├── test/ // Test files
│ ├── app_test.dart // Main app tests
│ ├── helpers/ // Test helpers and mocks
│ ├── models/ // Model tests
│ ├── controllers/ // Controller tests
│ ├── services/ // Service tests
│ └── widgets/ // Widget tests
├── docs/ // Documentation
│ ├── architecture.md // This file
│ ├── feature_inventory.md // Feature tracking
│ ├── development_guidelines.md // Coding standards
│ └── previous_workflows/ // Implementation history
├── functions/ // Firebase Cloud Functions
│ └── src/
│   └── index.ts // Cloud Functions implementation
├── pubspec.yaml // Dependencies
└── README.md // Project overview


## Architectural Patterns

- **State Management:**  
  We use Provider to manage application state in a predictable way across widgets and screens.
  - VideoCollectionManager for liked and saved videos state
  - Optimistic updates for immediate UI feedback
  - Real-time Firestore synchronization

- **Service Layer:**  
  All Firebase integrations (Authentication, Firestore, Storage, Messaging) are encapsulated in service classes inside `lib/services/`. This ensures that interactions with external systems are abstracted and maintainable.

- **Cloud Functions:**
  Firebase Cloud Functions handle server-side operations and automated tasks:
  - Located in `/functions` directory using TypeScript
  - Currently deployed functions:
    - `createUserProfile`: Automatically creates a user profile document in Firestore when a new user signs up
      - Triggers on Firebase Auth user creation
      - Creates default profile with username derived from display name
      - Sets up initial fields: email, username, bio, photoURL, createdAt, updatedAt
  - Uses Node.js 20 runtime
  - Implements error handling and logging
  - Maintains data consistency between Auth and Firestore

- **Reusable Widgets:**  
  Shared UI components are organized in `lib/widgets/` to avoid code duplication and maintain consistency:
  - Authentication widgets at the root level (to be organized into auth/ directory)
  - Video viewing components in `widgets/video_viewing/`
  - Common components at the root of `widgets/`

- **Navigation & Routing:**  
  We use Flutter's Navigator for screen transitions:
  - The `AuthWrapper` in `main.dart` handles the main authentication flow:
    - Unauthenticated users see the `LoginScreen`
    - Authenticated users see the `FrontPage` (video viewing screen)
  - Profile navigation is handled through the bottom navigation bar:
    - Profile icon navigates to `ProfileScreen`
    - Includes user profile management and logout functionality

- **Coding Practices & Conventions:**  
  Adhering to Dart's style guidelines and our defined nomenclature in [docs/development_guidelines.md](docs/development_guidelines.md), we use clear naming conventions (PascalCase for classes, camelCase for variables and functions, underscores for file names) and enforce modularity with a clean separation between UI, business logic, and data models.

- **Dependency Management:**  
  Wherever applicable, we use the singleton pattern (e.g., in AuthService) and dependency injection techniques to ensure a clean and maintainable codebase.

- **Clean Architecture:**  
  Our codebase aims to separate concerns by organizing code into models, screens, services, and widgets. This enables scalability and easier testing of individual components.

## Implementation Status

### Implemented Features
- Authentication (Email/Password and Google Sign-in)
- Video Playback and Feed
- Like/Save Functionality
- Comments System
- Profile Management
- Basic Navigation

### Planned Features
- User Collections
- Push Notifications
- Video Filtering
- Common UI Components
- Advanced Search

## Video Playback Implementation

1. **Video Model** (`models/video.dart`):
   - Handles Firestore document conversion
   - Validates required fields (url, userId, title)
   - Implements URL validation
   - Manages video metadata
   - Links videos to creator profiles via userId
   - Manages likes using Set<String> for efficient storage
   - Provides helper methods for like status and count
   - Currently supports .mov format (iPhone default)
   - (TODO) Define and implement video size limitations based on:
     - Firebase Storage quotas
     - App performance considerations
     - User experience (upload/download times)
     - Mobile data usage optimization

2. **Video Feed** (`widgets/video_viewing/video_feed.dart`):
   - Uses PageView.builder for smooth vertical scrolling
   - Manages video state and transitions
   - Handles current video tracking
   - Provides video change notifications
   - Implements double-tap to like functionality
   - Shows heart animation on like actions
   - Prepares for creator data prefetching

3. **Video Background** (`widgets/video_viewing/video_background.dart`):
   - Manages video player lifecycle
   - Implements auto-play and looping
   - Provides error handling with user-friendly messages
   - Shows loading states on black background

4. **Creator Info Display** (`widgets/video_viewing/creator_info_group.dart`):
   - Real-time creator profile streaming
   - Loading states with skeleton UI
   - Error handling with user feedback
   - Profile picture display with fallbacks
   - Username/display name handling
   - Video title and description display

5. **Like Animation** (`widgets/video_viewing/like_animation.dart`):
   - Implements TikTok-style heart animations
   - Handles both button and double-tap triggers
   - Provides haptic feedback
   - Shows popup animation at tap location
   - Animates like count changes
   - Manages animation states and cleanup

6. **Front Page** (`screens/video_viewing_screen.dart`):
   - Integrates with Firestore for video data
   - Manages current video state
   - Coordinates video feed and creator info
   - Handles optimistic updates for likes:
     - Tracks pending updates in _optimisticLikes set
     - Updates UI immediately
     - Reverts on error with user feedback
   - Provides debug information during development
   - Manages UI layout with Stack widget

The implementation follows these key principles:
- Proper lifecycle management of video controllers
- Real-time data streaming for creator profiles and likes
- Optimistic updates for responsive UI
- Graceful error handling with user feedback
- Debug information during development
- Clear separation of concerns between data, playback, and UI

## Data Flow

1. **Video Data Flow**:
   ```
   Firestore videos collection
   → Video model
   → VideoFeed
   → Current video state in FrontPage
   → CreatorInfoGroup
   ```

2. **Creator Profile Flow**:
   ```
   Video.userId
   → Firestore users collection
   → Real-time profile stream
   → CreatorInfoGroup display
   ```

3. **Like Action Flow**:
   ```
   User interaction (double-tap/button)
   → Optimistic UI update
   → Firestore transaction
   → Real-time likes stream
   → UI refresh on confirmation/error
   ```

4. **Comment Flow**:
   ```
   Comment Creation:
   User input → CommentInput
   → Firestore transaction (atomic update)
     ├── Add comment to subcollection
     └── Increment video comment count
   → Real-time comment stream update
   → UI refresh (CommentList & comment count)

   Comment Display:
   Firestore comments subcollection
   → Comment model
   → CommentList
   → CommentTile
     └── User profile stream for each comment

   Comment Deletion:
   Delete action → Firestore transaction
     ├── Remove comment from subcollection
     └── Decrement video comment count
   → Real-time updates to UI
   ```

5. **State Management**:
   - Video state managed by FrontPage
   - Profile data streamed directly in CreatorInfoGroup
   - Like states managed with optimistic updates
   - Comment state managed through real-time streams
   - Loading and error states handled at component level

## Error Handling

1. **Video Validation**:
   - URL format checking
   - Required field validation
   - Creator existence verification

2. **Profile Data**:
   - Graceful handling of missing profiles
   - Loading state display
   - Clear error messages
   - Fallback UI for missing data

3. **User Experience**:
   - Skeleton loading UI
   - Informative error states
   - Fallback profile pictures
   - Default text for missing data

## Video Collections Implementation

1. **VideoState Model**:
   - Immutable state representation for videos
   - Tracks like and save status
   - Manages counts and user interactions
   - Provides optimistic update methods

2. **VideoCollectionManager** (`controllers/video_collection_manager.dart`):
   - Central state management for video collections
   - Real-time synchronization with Firestore
   - Manages liked and saved video states
   - Provides optimistic updates for interactions
   - Handles error states and recovery
   - Implements Provider pattern for state distribution

3. **SavedVideosScreen** (`screens/saved_videos_screen.dart`):
   - Tabbed interface for liked and saved videos
   - Real-time updates via VideoCollectionManager
   - Reusable VideoGrid component
   - Remove functionality with optimistic updates
   - Loading and error states
   - Empty state handling

4. **Data Flow for Collections**:
   ```
   User Interaction (like/save)
   → VideoCollectionManager
     ├── Optimistic UI update
     ├── Firestore transaction
     └── Real-time state update
   → UI refresh (VideoGrid/RightActionsColumn)
   ```

The implementation follows these principles:
- Single source of truth for video states
- Immediate UI feedback with optimistic updates
- Proper error handling and recovery
- Clear separation of concerns
- Reusable components
- Comprehensive test coverage

## State Management

Our application uses a layered state management approach that combines Provider for dependency injection with a custom state management system for video interactions. This system is designed to provide:

1. **Optimistic Updates**: Immediate UI feedback for user actions
2. **State Persistence**: Efficient caching and local storage
3. **Background Operations**: Asynchronous server updates
4. **Error Recovery**: Automatic state reconciliation

### Core Components

#### 1. State Layer (`lib/state/`)
- `VideoState`: Immutable state class representing video UI state
  ```dart
  class VideoState {
    final String videoId;
    final bool isLiked;
    final bool isSaved;
    final DateTime lastUpdated;
    final Video? videoData;
    final bool isLoading;
    final String? error;
  }
  ```
- `VideoStateCache`: LRU cache implementation for memory efficiency
  - Fixed-size cache with LRU eviction
  - Change notifications for UI updates
  - Automatic stale data cleanup
- `VideoStateStorage`: Persistent storage using SharedPreferences
  - Serialization/deserialization of states
  - Data versioning and migration
  - Background cleanup operations

#### 2. Controller Layer (`lib/controllers/`)
- `VideoCollectionManager`: Central state coordinator
  - Coordinates between cache and storage
  - Handles optimistic updates
  - Manages background operations
  - Provides error recovery
  - Exposes state through Provider

### Data Flow

1. **User Interaction**
   ```
   User Action (like/save)
   → VideoCollectionManager
     ├── Immediate cache update
     ├── Storage persistence
     ├── Server update
     └── Background refresh
   → UI update via ChangeNotifier
   ```

2. **State Recovery**
   ```
   Error Detection
   → Revert cache state
   → Update storage
   → Notify UI
   → Log error
   ```

3. **Background Operations**
   ```
   Server Update
   → Update cache if needed
   → Refresh collections
   → Clean stale data
   ```

### Performance Optimizations

1. **Memory Management**
   - LRU cache with configurable size
   - Automatic cleanup of stale data
   - Efficient state storage format

2. **UI Responsiveness**
   - Immediate feedback through optimistic updates
   - Background processing for heavy operations
   - Debounced storage operations

3. **Network Efficiency**
   - Batched server updates
   - Background collection refreshes
   - Cached state reconciliation

### Implementation Guidelines

1. **State Updates**
   - Always use immutable state objects
   - Apply optimistic updates immediately
   - Handle errors with state reversion
   - Maintain consistency across layers

2. **Cache Management**
   - Monitor cache size and performance
   - Implement proper cleanup strategies
   - Handle eviction gracefully

3. **Storage Operations**
   - Version data structures
   - Implement migration strategies
   - Clean up old data periodically

4. **Error Handling**
   - Log all errors for debugging
   - Provide user feedback when appropriate
   - Implement recovery mechanisms
   - Maintain data consistency

---

This architecture file reflects our current codebase within the `/lib` directory. As new features and modules are added, please update this document accordingly to maintain an accurate overview of the project structure.