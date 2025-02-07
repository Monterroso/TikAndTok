# User Profile Implementation Workflow

## Overview
This document outlines the implementation plan for viewing other users' profiles in our TikTok clone application. The feature enables users to view other users' profiles, their videos, and interact through following/unfollowing.

## Design Goals
- Create an intuitive profile viewing experience
- Reuse existing components where possible
- Maintain performance with real-time updates
- Support smooth navigation between profile and video views
- Keep implementation consistent with existing patterns

## Core Components

### 1. User Profile Screen
*Location:* `lib/screens/user_profile_screen.dart`

#### UI Components
```dart
class UserProfileScreen extends StatelessWidget {
  final String userId;
  final UserProfileController controller;

  // Components:
  // - Profile Header (avatar, username, bio)
  // - Stats Row (video count, followers, following)
  // - Follow Button
  // - Video Grid
  // - Loading States
  // - Error Handling
}
```

#### Features
- Real-time profile data updates
- Follow/Unfollow functionality
- Video grid with pagination
- Pull-to-refresh
- Proper error states
- Loading skeletons
- Navigation to full video feed

### 2. User Videos Feed Screen
*Location:* `lib/screens/user_videos_feed_screen.dart`

#### Implementation
```dart
class UserVideosFeedScreen extends StatelessWidget {
  final String userId;
  final int initialVideoIndex;
  final UserVideosFeedController controller;

  // Reuses existing VideoFeed widget
  // Filtered to show only user's videos
  // Maintains video context
}
```

#### Features
- Vertical swipeable feed
- Only shows selected user's videos
- Maintains video order from grid
- Uses existing video player
- Proper error handling
- Loading states

### 3. Controllers

#### UserProfileController
*Location:* `lib/controllers/user_profile_controller.dart`
```dart
class UserProfileController extends ChangeNotifier {
  final String userId;
  final FirestoreService _firestoreService;
  
  // State management:
  // - Profile data
  // - Follow status
  // - Video grid data
  // - Loading states
  // - Error handling
}
```

#### UserVideosFeedController
*Location:* `lib/controllers/user_videos_feed_controller.dart`
```dart
class UserVideosFeedController extends VideoFeedController {
  final String userId;
  
  // Extends existing VideoFeedController
  // Overrides video fetching to filter by user
  // Maintains feed state
}
```

### 4. Models

#### Enhanced UserProfile
*Location:* `lib/models/user_profile.dart`
```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String username,
    required String photoURL,
    required String bio,
    required int videoCount,
    required int followerCount,
    required int followingCount,
    required bool isFollowing,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

## Database Structure

### Firestore Collections

1. **users/{userId}**
   ```json
   {
     "username": "string",
     "photoURL": "string",
     "bio": "string",
     "videoCount": "number",
     "followerCount": "number",
     "followingCount": "number",
     "createdAt": "timestamp",
     "updatedAt": "timestamp"
   }
   ```

2. **users/{userId}/followers/{followerId}**
   ```json
   {
     "userId": "string",
     "timestamp": "timestamp"
   }
   ```

3. **users/{userId}/following/{followedId}**
   ```json
   {
     "userId": "string",
     "timestamp": "timestamp"
   }
   ```

### Indexes Required
```json
{
  "indexes": [
    {
      "collectionGroup": "videos",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

## Implementation Order

### Phase 1: Core Profile View
1. Create UserProfile model
2. Implement UserProfileController
3. Build basic UserProfileScreen
4. Add profile navigation from:
   - Search results
   - Video creator info
   - Comment user info

### Phase 2: Video Integration
1. Implement UserVideosFeedController
2. Create UserVideosFeedScreen
3. Add video grid to profile
4. Implement grid-to-feed navigation

### Phase 3: Follow System
1. Add followers/following collections
2. Implement follow/unfollow functionality
3. Add real-time follower count updates
4. Update UI for follow status

### Phase 4: Performance Optimization
1. Implement profile data caching
2. Add pagination for video grid
3. Optimize follow status checks
4. Add proper loading states

## Technical Considerations

### Performance
- Cache profile data locally
- Paginate video grid (10-15 items)
- Lazy load video thumbnails
- Debounce follow/unfollow
- Optimize Firestore queries

### State Management
- Use Provider for dependency injection
- Use Freezed for immutable states
- Implement proper error handling
- Handle edge cases (deleted users, etc.)

### UI/UX
- Smooth transitions between views
- Loading skeletons for profile data
- Error states with retry options
- Pull-to-refresh functionality
- Proper back navigation

### Testing Strategy
1. Unit tests for controllers
2. Widget tests for profile UI
3. Integration tests for navigation
4. Performance testing for video grid

## Success Criteria
- Profile loads within 500ms
- Video grid scrolls smoothly
- Follow/unfollow updates immediately
- Error states handled gracefully
- Navigation works consistently

## Future Enhancements
- Profile sharing
- Blocked users handling
- Enhanced profile customization
- Activity feed
- Direct messaging

## Dependencies
- Existing VideoGrid component
- Firestore service
- Provider for state management
- Freezed for immutable states

This implementation plan provides a comprehensive approach to adding user profile viewing functionality while maintaining consistency with our existing architecture and ensuring a smooth user experience. 