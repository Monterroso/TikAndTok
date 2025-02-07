# Video Feed System Refactor

## Overview

This document outlines the plan for refactoring our video feed system to support multiple feed types (Home, Likes, Saved) with a unified, reusable architecture. The new system will build upon our existing VideoFeed and VideoBackground components while adding support for different feed types.

## Goals

1. Extend our existing video feed component to handle different types of video collections
2. Implement pagination for better performance with large collections
3. Maintain consistent UI/UX across different feed types
4. Handle video removal states gracefully
5. Provide clear feedback for user actions

## Architecture

### 1. Core Components

#### VideoFeedController Integration
```dart
abstract class VideoFeedController {
  final String feedTitle;
  final bool showBackButton;
  final VideoCollectionManager collectionManager;

  // Core functionality
  Future<List<Video>> getNextPage(String? lastVideoId, int pageSize);
  Future<void> onVideoInteraction(Video video);
  bool shouldKeepVideo(Video video);  // Sync check for UI
}
```

#### Specialized Controllers (Implementing in Order)
1. `HomeFeedController`: Main feed showing all videos (existing functionality)
2. `LikedVideosFeedController`: Shows only liked videos
3. `SavedVideosFeedController`: Shows only saved videos

#### Enhanced VideoFeed Widget
- Extend current VideoFeed to support:
  - Pagination
  - Feed-specific state management
  - Feed header when needed
  - Feedback for video removal

### 2. User Interface Components

#### Feed Header (When Needed)
- Dynamic title based on feed type
- Back button for liked/saved feeds
- Consistent styling across feeds

#### Video Player Integration
- Continue using existing VideoBackground
- Maintain current video until scroll away
- Add state change handling for unlike/unsave

## Implementation Plan

### Phase 1: Core Architecture & Home Feed (MVP)

1. **Extend Current VideoFeed**
   - [ ] Add pagination support to existing VideoFeed
   - [ ] Integrate with VideoCollectionManager
   - [ ] Implement scroll position memory
   - [ ] Add loading states for pagination

2. **Create HomeFeedController**
   - [ ] Implement pagination with Firestore
   - [ ] Integrate with existing video state management
   - [ ] Optimize performance

### Phase 2: Liked Videos Feed

1. **Create LikedVideosFeedController**
   - [ ] Filter for liked videos using VideoCollectionManager
   - [ ] Handle unlike actions
   - [ ] Implement feedback messages
   - [ ] Add header with back navigation

2. **UI Components**
   - [ ] Create FeedHeader for liked videos
   - [ ] Handle video removal animations
   - [ ] Implement smooth transitions

### Phase 3: Saved Videos Feed

1. **Create SavedVideosFeedController**
   - [ ] Filter for saved videos using VideoCollectionManager
   - [ ] Handle unsave actions
   - [ ] Implement feedback messages
   - [ ] Add header with back navigation

2. **UI Components**
   - [ ] Reuse FeedHeader component
   - [ ] Handle video removal animations
   - [ ] Implement smooth transitions

### Phase 4: Testing & Optimization

1. **Testing Implementation**
   - [ ] Unit tests for controllers
   - [ ] Widget tests for UI components
   - [ ] Integration tests for feed switching

2. **Performance Optimization**
   - [ ] Implement efficient page loading
   - [ ] Add prefetching for next page
   - [ ] Optimize memory usage
   - [ ] Handle edge cases

## Success Criteria

1. **Functionality**
   - Smooth scrolling through videos
   - Proper pagination
   - Correct video filtering
   - Appropriate feedback for actions

2. **Performance**
   - Quick initial load time
   - Smooth infinite scroll
   - Efficient memory usage
   - No UI jank

3. **User Experience**
   - Consistent UI across feeds
   - Clear feedback for actions
   - Intuitive navigation
   - Graceful error handling

## Dependencies

1. **Existing Components to Reuse**
   - VideoBackground (video playback)
   - VideoFeed (base implementation)
   - CreatorInfoGroup
   - RightActionsColumn
   - VideoCollectionManager

2. **Required Services**
   - FirestoreService
   - VideoCollectionManager
   - AuthService

## Timeline (MVP Focus)

1. Phase 1: Core Architecture & Home Feed (2-3 days)
2. Phase 2: Liked Videos Feed (2 days)
3. Phase 3: Saved Videos Feed (2 days)
4. Phase 4: Testing & Optimization (1-2 days)

## Future Enhancements (Post-MVP)

1. Advanced video prefetching
2. Customizable feed filters
3. Enhanced analytics
4. Improved caching
5. Offline support

---

This implementation plan will be updated as we progress through the development phases. Each completed item should be checked off and any deviations or additional requirements should be documented here. 