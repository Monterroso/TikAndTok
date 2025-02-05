import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/video.dart';
import '../widgets/video_viewing/video_feed.dart';
import '../widgets/video_viewing/top_search_button.dart';
import '../widgets/video_viewing/right_actions_column.dart';
import '../widgets/video_viewing/creator_info_group.dart';
import '../widgets/video_viewing/custom_bottom_navigation_bar.dart';

/// FrontPage is the main entry point for the D&D TikTok clone's video display.
/// It sets up a layered UI using a full-screen stack:
/// - The VideoFeed provides a swipeable list of full-screen videos.
/// - The TopSearchButton is positioned at the top-right for searches.
/// - The RightActionsColumn displays buttons for like, comments, save, share, 
///   and music info in a vertical column on the right edge.
/// - The CreatorInfoGroup shows the creator's profile picture, follow button, username,
///   and video title at the bottom-left.
/// - The CustomBottomNavigationBar is fixed at the bottom with upload and profile actions.
class FrontPage extends StatefulWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  Video? _currentVideo;
  final _firestoreService = FirestoreService();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  // Keep track of optimistic updates
  final Set<String> _optimisticLikes = {};

  void _handleVideoChanged(Video video) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentVideo = video;
        // Clear optimistic likes when video changes
        _optimisticLikes.clear();
      });
    });
  }

  Future<void> _handleLikeChanged(bool liked) async {
    if (_currentVideo == null || _currentUserId == null) return;

    // Optimistically update the UI
    setState(() {
      if (liked) {
        _optimisticLikes.add(_currentVideo!.id);
      } else {
        _optimisticLikes.remove(_currentVideo!.id);
      }
    });

    try {
      await _firestoreService.toggleLike(
        videoId: _currentVideo!.id,
        userId: _currentUserId,
      );
    } catch (e) {
      // Revert optimistic update on error
      if (!mounted) return;
      setState(() {
        if (liked) {
          _optimisticLikes.remove(_currentVideo!.id);
        } else {
          _optimisticLikes.add(_currentVideo!.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${liked ? 'like' : 'unlike'} video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get current like status considering optimistic updates
  bool _isVideoLiked(Video video) {
    if (_currentUserId == null) return false;
    
    // Get the actual server state
    final serverLikeStatus = video.isLikedByUser(_currentUserId!);
    
    // Check if we have a pending optimistic update
    final hasOptimisticUpdate = _optimisticLikes.contains(video.id);
    
    // If we have an optimistic update, toggle the server state
    // Otherwise, use the server state as is
    return hasOptimisticUpdate ? !serverLikeStatus : serverLikeStatus;
  }

  // Helper method to get like count considering optimistic updates
  int _getLikeCount(Video video) {
    if (_currentUserId == null) return video.likeCount;
    
    // Get the server states
    final serverLikeStatus = video.isLikedByUser(_currentUserId!);
    final serverLikeCount = video.likeCount;
    
    // Check if we have a pending optimistic update
    final hasOptimisticUpdate = _optimisticLikes.contains(video.id);
    
    if (!hasOptimisticUpdate) {
      // No optimistic update, use server count
      return serverLikeCount;
    }
    
    // If we have an optimistic update, adjust the count based on the change
    return serverLikeStatus ? serverLikeCount - 1 : serverLikeCount + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Please sign in to view videos',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Debug information or VideoFeed
          StreamBuilder<List<Video>>(
            stream: _firestoreService.streamVideos(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Debug: Firebase Error\n'
                      '${snapshot.error is FormatException ? "Invalid video data: " : ""}'
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text(
                    'Debug: Waiting for Firebase data...',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              final videos = snapshot.data ?? [];
              if (videos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Debug: No videos in Firebase\n'
                      'Collection: videos\n'
                      'Required fields:\n'
                      '- url (string, valid URL)\n'
                      '- userId (string)\n'
                      '- title (string)\n'
                      '- createdAt (timestamp)',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Filter out videos with invalid URLs
              final validVideos = videos.where((video) => 
                video.url.startsWith('http://') || 
                video.url.startsWith('https://')
              ).toList();

              if (validVideos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Debug: No valid video URLs found\n'
                      'Videos exist but URLs are invalid\n'
                      'URLs must start with http:// or https://',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return VideoFeed(
                videos: validVideos,
                onVideoChanged: _handleVideoChanged,
                onLikeChanged: _currentVideo != null ? _handleLikeChanged : null,
                isCurrentVideoLiked: _currentVideo != null ? _isVideoLiked(_currentVideo!) : false,
                currentVideoLikeCount: _currentVideo != null ? _getLikeCount(_currentVideo!) : 0,
              );
            },
          ),
          
          // TopSearchButton positioned at the top-right with padding
          const Positioned(
            top: 16.0,
            right: 16.0,
            child: TopSearchButton(),
          ),
          
          // RightActionsColumn holds the interactive buttons
          if (_currentVideo != null) Positioned(
            top: 100.0,
            right: 16.0,
            bottom: 100.0,
            child: RightActionsColumn(
              video: _currentVideo!,
              currentUserId: _currentUserId!,
              onLikeChanged: _handleLikeChanged,
              isLiked: _isVideoLiked(_currentVideo!),
              likeCount: _getLikeCount(_currentVideo!),
            ),
          ),
          
          // CreatorInfoGroup displays creator details
          Positioned(
            left: 16.0,
            right: 72.0, // Give space for the right action buttons
            bottom: 80.0,
            child: CreatorInfoGroup(video: _currentVideo),
          ),
          
          // CustomBottomNavigationBar fixed at the bottom
          const Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: CustomBottomNavigationBar(),
          ),
        ],
      ),
    );
  }
} 