# Application Architecture Overview

This document outlines the overall structure and design of our technical showcase video platform. It is intended to provide a clear view of the project organization, the responsibilities of each component, and the architectural patterns we follow.

## Project Purpose

Our platform is a Flutter application using Firebase as its backend, centered on enabling developers to showcase their technical implementations through short-form videos. The app allows users to browse, watch, and interact with videos demonstrating various technical solutions, frameworks, and architectural patterns.

## Directory Structure

Below is a visual breakdown of the project directories and key files. This structure promotes modularity, reusability, and clear separation of concerns: 

TikAndTok/
├── android/ // Native Android code & configuration
├── ios/ // Native iOS code & configuration (includes GoogleService-Info.plist)
├── lib/
│ ├── models/ // Data models for the application
│ │ ├── user_profile.dart // User profile model with Firestore integration
│ │ ├── video.dart // Video model with thumbnails and validation
│ │ │ └── Video // Core video class
│ │ │   ├── Properties // id, url, userId, title, thumbnailUrl
│ │ │   ├── Firestore conversion // fromFirestore, toFirestore
│ │ │   ├── Validation // URL and required fields
│ │ │   ├── Like management // likedBy Set<String>
│ │ │   └── Save management // savedBy Set<String>
│ │ ├── comment.dart // Comment model for video interactions
│ │ ├── search.dart // Search state and models using Freezed
│ │ │ └── SearchState // Core search state class
│ │ │   ├── Properties // query, isLoading, error, results
│ │ │   ├── Factory constructors // initial, loading, error states
│ │ │   └── JSON serialization // Freezed-generated code
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
│ │ ├── search_screen.dart // Search interface for videos and users
│ │ │ └── Components // Search screen components
│ │ │   ├── SearchBar // Debounced search input
│ │ │   ├── RecentSearches // Local search history
│ │ │   ├── UserResults // Horizontal user cards
│ │ │   └── SearchResults // Combined results view
│ │ ├── video_viewing_screen.dart // Main video viewing screen with FrontPage widget
│ │ │ └── FrontPage // Core widget managing video feed and UI layout
│ │ │   ├── StreamBuilder<List<Video>> // Real-time video data from Firestore
│ │ │   ├── VideoCollectionManager Integration // Manages video states and interactions
│ │ │   └── UI Components // Positioned overlay elements
│ │ ├── profile_screen.dart // User profile management screen with image upload
│ │ ├── saved_videos_screen.dart // Displays liked and saved videos in a tabbed interface
│ │ ├── saved_videos_feed_screen.dart // Vertical feed view for saved/liked videos
│ │ │ └── SavedVideosFeedScreen // Collection-specific feed implementation
│ │ │   ├── VideoFeed integration // Vertical swipeable interface
│ │ │   ├── Collection filtering // Based on liked/saved status
│ │ │   └── UI Components // Header, actions, creator info
│ │ ├── liked_videos_feed_screen.dart // (Deprecated) Merged into saved_videos_feed_screen
│ │ ├── filter_screen.dart // (Planned) Allows filtering of videos by various criteria
│ │ └── collections_screen.dart // (Planned) UI for managing user-created collections
│ ├── controllers/ // Business logic and state coordination
│ │ ├── search_controller.dart // Search functionality controller
│ │ │ └── SearchController // Manages search state and operations
│ │ │   ├── State management // SearchState updates
│ │ │   ├── Debounced search // 300ms delay
│ │ │   ├── Recent searches // Local storage integration
│ │ │   └── Error handling // Search failures
│ │ ├── search_video_feed_controller.dart // Search results video feed
│ │ │ └── SearchVideoFeedController // Manages search results playback
│ │ │   ├── Results management // Filtered video list
│ │ │   ├── Pagination // Search-specific loading
│ │ │   └── State handling // Loading and errors
│ │ ├── video_feed_controller.dart // Base abstract class for feed controllers
│ │ │ └── VideoFeedController // Abstract feed controller
│ │ │   ├── Core feed functionality // getNextPage, onVideoInteraction
│ │ │   ├── State management // loading, error states
│ │ │   └── Feed configuration // title, back button
│ │ ├── home_feed_controller.dart // Main feed implementation
│ │ ├── liked_videos_feed_controller.dart // Liked videos feed
│ │ ├── saved_videos_feed_controller.dart // Saved videos feed
│ │ └── video_collection_manager.dart // Manages video collections and interactions
│ │   └── VideoCollectionManager // Central state coordinator
│ │     ├── State management // cache and storage coordination
│ │     ├── Optimistic updates // immediate UI feedback
│ │     ├── Background operations // server updates
│ │     └── Error recovery // state reconciliation
│ ├── services/ // Service layer handling business logic and Firebase interactions
│ │ ├── auth_service.dart // Authentication operations
│ │ ├── firestore_service.dart // CRUD operations for Cloud Firestore
│ │ │ ├── User Operations // Methods for user data management
│ │ │ │ ├── createUserProfile() // Create new user with lowercase username
│ │ │ │ ├── updateUserProfile() // Update user data with validation
│ │ │ │ ├── searchUsers() // Case-insensitive username search
│ │ │ │ └── validateUsername() // Username format validation
│ │ │ ├── Video Operations // Methods for video data management
│ │ │ │ ├── streamVideos() // Real-time video feed with pagination
│ │ │ │ ├── getNextVideos() // Fetch next batch of videos
│ │ │ │ ├── createVideo() // Add new video document
│ │ │ │ ├── updateVideoStats() // Update video metrics
│ │ │ │ ├── toggleLike() // Toggle video like status
│ │ │ │ ├── toggleSave() // Toggle video save status
│ │ │ │ ├── searchVideos() // Title-based video search
│ │ │ │ └── getVideoCollections() // Fetch user's video collections
│ │ │ └── Search Operations // Methods for search functionality
│ │ │   ├── searchUsers() // Username search with case-insensitive matching
│ │ │   ├── searchVideos() // Title-based video search with pagination
│ │ │   └── getNextFilteredVideos() // Pagination for search results
│ │ ├── firebase_storage_service.dart // Manages video uploads and downloads
│ │ └── messaging_service.dart // (Planned) Handles push notifications
│ ├── widgets/ // Reusable UI components across the app
│ │ ├── video_viewing/ // Video viewing screen components
│ │ │ ├── video_background.dart // Video playback with error handling
│ │ │ │ └── VideoBackground // Manages video player lifecycle
│ │ │   ├── Auto-play and looping
│ │ │   ├── Error states with messages
│ │ │   ├── Loading indicators
│ │ │   ├── Orientation handling:
│ │ │   │   ├── Automatic detection from dimensions
│ │ │   │   ├── 90-degree rotation for landscape
│ │ │   │   ├── Dynamic scaling with SizedBox.expand
│ │ │   │   └── AspectRatio preservation
│ │ │   └── Proper cleanup on disposal
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

### Core Video Features
- Video Feed with infinite scroll and optimized playback
- Video Grid display with thumbnail support
- Video upload and metadata management
- Like and save functionality for videos
- Video state management using Provider

### User Features
- User authentication and profile management
- User video collections (liked and saved videos)
- Profile customization and settings

### Search and Discovery
- Real-time video search with debounce
- User search functionality
- Recent searches history
- Search results caching

### Media Management
- Thumbnail support for video previews
- Efficient media loading and caching
- Placeholder handling for missing thumbnails
- Video metadata validation

### UI/UX
- Responsive grid layouts
- Loading states and error handling
- Smooth transitions and animations
- Cross-platform compatibility

## Planned Features

1. **Enhanced Video Management**
   - Automated thumbnail generation
   - Multiple resolution support
   - Progressive loading
   - Advanced caching strategy

2. **Advanced Search**
   - Tag-based search
   - Category filtering
   - Enhanced result ranking
   - Search history sync

3. **User Interactions**
   - Follow/Unfollow system
   - Activity feed
   - Enhanced profile customization
   - Direct messaging

## Performance Considerations

1. **Video Optimization**
   - Thumbnail implementation for faster loading
   - Video preloading for smooth playback
   - Efficient memory management
   - Cache cleanup strategies

2. **State Management**
   - Optimistic updates for immediate feedback
   - Real-time synchronization
   - Error recovery mechanisms
   - Local state persistence

3. **Search Performance**
   - Debounced queries
   - Paginated results
   - Efficient Firestore queries
   - Local storage for recent searches

4. **UI Performance**
   - Lazy loading of thumbnails
   - Efficient grid layouts
   - Smooth animations
   - Loading state management

## Security Considerations

1. **Authentication**
   - Secure session management
   - Protected routes
   - Email verification
   - Password reset functionality

2. **Data Access**
   - Firestore security rules
   - User data protection
   - Content access control
   - Rate limiting

3. **File Storage**
   - Secure video upload
   - Protected thumbnail storage
   - Access control
   - Content validation

## Testing Strategy

1. **Unit Tests**
   - Controller logic
   - Model validation
   - Service methods
   - Utility functions

2. **Widget Tests**
   - UI components
   - User interactions
   - State management
   - Error handling

3. **Integration Tests**
   - Authentication flow
   - Video playback
   - Search functionality
   - Collection management

4. **Performance Tests**
   - Video loading
   - Search response time
   - Thumbnail loading
   - State updates

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
   - Integrates with Gemini-powered technical analysis

2. **VideoAnalysis Model** (`models/video_analysis.dart`):
   - Stores technical analysis of videos
   - Tracks implementation details
   - Manages tech stack information
   - Records architectural patterns
   - Lists identified best practices
   - Handles processing state and errors

3. **Technical Metadata Display** (`widgets/video_viewing/technical_metadata_display.dart`):
   - Shows implementation overview
   - Displays tech stack tags
   - Lists architectural patterns
   - Highlights best practices
   - Provides loading and error states

4. **AI Comment Integration**:
   - Triggers on "Just Submit" keyword
   - Provides technical insights
   - References video analysis data
   - Maintains conversation context
   - Uses Gemini for response generation

5. **Video Feed** (`widgets/video_viewing/video_feed.dart`):
   - Uses PageView.builder for smooth vertical scrolling
   - Manages video state and transitions
   - Handles current video tracking
   - Provides video change notifications
   - Implements double-tap to like functionality
   - Shows heart animation on like actions
   - Prepares for creator data prefetching

6. **Video Background** (`widgets/video_viewing/video_background.dart`):
   - Manages video player lifecycle
   - Implements auto-play and looping
   - Provides error handling with user-friendly messages
   - Shows loading states on black background

7. **Creator Info Display** (`widgets/video_viewing/creator_info_group.dart`):
   - Real-time creator profile streaming
   - Loading states with skeleton UI
   - Error handling with user feedback
   - Profile picture display with fallbacks
   - Username/display name handling
   - Video title and description display

8. **Like Animation** (`widgets/video_viewing/like_animation.dart`):
   - Implements TikTok-style heart animations
   - Handles both button and double-tap triggers
   - Provides haptic feedback
   - Shows popup animation at tap location
   - Animates like count changes
   - Manages animation states and cleanup

9. **Front Page** (`screens/video_viewing_screen.dart`):
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
   - Exposes getters for liked and saved videos
   - Manages video state caching and persistence

3. **SavedVideosScreen** (`screens/saved_videos_screen.dart`):
   - Tabbed interface for liked and saved videos
   - Real-time updates via VideoCollectionManager
   - Reusable VideoGrid component
   - Remove functionality with optimistic updates
   - Loading and error states
   - Empty state handling
   - Navigation to collection-specific feeds

4. **SavedVideosFeedScreen** (`screens/saved_videos_feed_screen.dart`):
   - Dedicated feed view for liked and saved videos
   - Vertical swipeable interface
   - Collection-specific filtering
   - Real-time state updates
   - Proper error handling
   - Loading states and feedback
   - Smooth transitions between videos
   - Back navigation with transparent header

5. **SavedVideosFeedController** (`controllers/saved_videos_feed_controller.dart`):
   - Extends VideoFeedController for collection-specific behavior
   - Manages pagination for filtered video sets
   - Handles collection-specific video filtering
   - Maintains video state consistency
   - Provides optimistic updates for interactions
   - Implements proper cleanup on disposal

6. **Data Flow for Collections**:
   ```
   User Interaction (like/save)
   → VideoCollectionManager
     ├── Optimistic UI update
     ├── Firestore transaction
     └── Real-time state update
   → UI refresh (VideoGrid/RightActionsColumn)
   
   Collection Feed Navigation
   → SavedVideosFeedScreen
     ├── Initialize SavedVideosFeedController
     ├── Load filtered videos
     └── Setup UI components
   → Real-time updates via VideoCollectionManager
   ```

The implementation follows these principles:
- Single source of truth for video states
- Immediate UI feedback with optimistic updates
- Proper error handling and recovery
- Clear separation of concerns
- Reusable components
- Comprehensive test coverage
- Smooth navigation between views
- Efficient state management
- Real-time synchronization

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

## User Profile Schema

Our user profile schema is designed to be simple and efficient:

```typescript
interface UserProfile {
  username: string;     // Required, unique, lowercase, only letters/numbers/underscores
  email: string;        // Required
  photoURL: string;     // Optional, defaults to ''
  bio: string;         // Optional, defaults to ''
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

Key characteristics:
- Username is stored in lowercase for case-insensitive matching
- Username is used as the unique identifier and display name
- Username validation: 3-30 characters, alphanumeric + underscores
- Bio has a 150-character limit
- Timestamps track creation and updates

## Search Implementation

The search functionality is implemented with a focus on performance and user experience:

### Components

1. **Search Screen** (`lib/screens/search_screen.dart`):
   - Debounced search input (300ms)
   - Recent searches with local storage
   - Sectioned results display:
     - Horizontal scrolling user results
     - Grid layout for video results
   - Loading states and error handling
   - Empty state messaging

2. **Search Controller** (`lib/controllers/search_controller.dart`):
   ```dart
   class SearchController extends ChangeNotifier {
     final FirestoreService _firestoreService;
     final SharedPreferences _prefs;
     Timer? _debounceTimer;
     SearchState _state;

     // Core functionality
     Future<void> search(String query);
     Future<void> clearRecentSearches();
     void _loadRecentSearches();
   }
   ```

3. **Search State** (`lib/models/search.dart`):
   ```dart
   @freezed
   class SearchState with _$SearchState {
     const factory SearchState({
       required String query,
       @Default(false) bool isLoading,
       String? error,
       @Default([]) List<Video> videoResults,
       @Default([]) List<Map<String, dynamic>> userResults,
       @Default([]) List<String> recentSearches,
     }) = _SearchState;
   }
   ```

### Data Flow

1. **Search Input**:
   ```
   User Input → Debounce (300ms)
   → SearchController.search()
   → Parallel Queries:
     ├── searchUsers() - Case-insensitive username search
     └── searchVideos() - Title-based video search
   → Update SearchState
   → UI Refresh
   ```

2. **Recent Searches**:
   ```
   Search Completion
   → Add to recent searches
   → Update SharedPreferences
   → Update SearchState
   → UI Refresh
   ```

3. **Result Selection**:
   ```
   User Result Selection
   → Navigate to user profile (TODO)

   Video Result Selection
   → Initialize SearchVideoFeedController
   → Navigate to video feed view
   → Start playback at selected index
   ```

### Search Indexing

1. **User Search Index**:
   - Username field indexed for case-insensitive search
   - Compound index with createdAt for sorting
   ```json
   {
     "collectionGroup": "users",
     "queryScope": "COLLECTION",
     "fields": [
       { "fieldPath": "username", "order": "ASCENDING" },
       { "fieldPath": "createdAt", "order": "DESCENDING" }
     ]
   }
   ```

2. **Video Search Index**:
   - Title field indexed for text search
   - Compound index with createdAt for sorting
   ```json
   {
     "collectionGroup": "videos",
     "queryScope": "COLLECTION",
     "fields": [
       { "fieldPath": "title", "order": "ASCENDING" },
       { "fieldPath": "createdAt", "order": "DESCENDING" }
     ]
   }
   ```

### Performance Optimizations

1. **Query Optimization**:
   - Debounced search to reduce database queries
   - Paginated results for both users and videos
   - Proper indexing for efficient queries

2. **UI Performance**:
   - Lazy loading of video thumbnails
   - Horizontal scrolling for user results
   - Grid layout for video results
   - Loading states for feedback

3. **State Management**:
   - Immutable state with Freezed
   - Efficient updates via ChangeNotifier
   - Local storage for recent searches
   - Error handling and recovery

### User Experience

1. **Search Interface**:
   - Clean, minimal design
   - Real-time feedback
   - Clear error messages
   - Empty state handling

2. **Results Display**:
   - Users shown with '@' prefix
   - Profile pictures with fallbacks
   - Video thumbnails in grid layout
   - Clear section headers

3. **Navigation**:
   - Smooth transitions
   - Back button for easy return
   - Recent searches for quick access
   - Clear history option

### Future Enhancements

1. **Planned Improvements**:
   - Advanced filtering options
   - Tag-based search
   - Search history sync
   - Enhanced result ranking

2. **Optimization Opportunities**:
   - Server-side search
   - Full-text search
   - Fuzzy matching
   - Result caching

## State Management Implementation

Our application uses a combination of Provider and Freezed for robust state management:

### Immutable State with Freezed

We use Freezed to create immutable state classes that are:
- Type-safe
- Immutable
- Easy to update with `copyWith`
- Automatically implement equality
- Support JSON serialization when needed

Example implementation:
```dart
@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    required String query,
    @Default(false) bool isLoading,
    String? error,
    @Default([]) List<Video> videoResults,
    @Default([]) List<Map<String, dynamic>> userResults,
    @Default([]) List<String> recentSearches,
  }) = _SearchState;

  factory SearchState.initial() => const SearchState(query: '');
  
  factory SearchState.loading(String query) => SearchState(
    query: query,
    isLoading: true,
  );

  factory SearchState.fromJson(Map<String, dynamic> json) => 
      _$SearchStateFromJson(json);
}
```

### State Management Patterns

1. **Controller Layer**
   ```dart
   class SearchController extends ChangeNotifier {
     SearchState _state = SearchState.initial();
     SearchState get state => _state;

     void updateState(SearchState newState) {
       _state = newState;
       notifyListeners();
     }
   }
   ```

2. **UI Integration**
   ```dart
   Consumer<SearchController>(
     builder: (context, controller, _) {
       final state = controller.state;
       // Use immutable state safely
     },
   )
   ```

3. **State Updates**
   ```dart
   // Immutable updates using copyWith
   _state = _state.copyWith(
     isLoading: false,
     videoResults: newVideos,
   );
   ```

### Benefits of This Approach

1. **Type Safety**
   - Compile-time checks for state updates
   - No runtime type errors
   - Clear state structure

2. **Immutability**
   - Prevents accidental state mutations
   - Makes state changes trackable
   - Enables efficient equality checks

3. **Developer Experience**
   - Generated code reduces boilerplate
   - Consistent patterns across the app
   - Easy to test and debug

4. **Performance**
   - Efficient updates with copyWith
   - Optimized equality checks
   - Minimal rebuilds

## Technical Considerations

### State Management
- Provider pattern for application-wide state
- Freezed for immutable state models
- Efficient state updates with minimal rebuilds
- Clear separation of UI and business logic

### Performance Optimization
- Lazy loading for video content
- Thumbnail caching and preloading
- Debounced search queries
- Widget tree optimization
- Memory management for video playback

### Data Architecture
- Firestore for real-time data
- Structured collections for videos, users, and interactions
- Efficient queries with proper indexing
- Batch operations for bulk updates

### Security
- Firebase Authentication integration
- Secure file storage access
- Data validation at model level
- Protected API endpoints

### Testing Strategy
- Unit tests for models and controllers
- Widget tests for UI components
- Integration tests for Firebase interaction
- Performance testing for video playback

### Code Organization
- Feature-based directory structure
- Reusable widgets and components
- Clear separation of concerns
- Documentation for complex features

---

This architecture file reflects our current codebase within the `/lib` directory. As new features and modules are added, please update this document accordingly to maintain an accurate overview of the project structure.