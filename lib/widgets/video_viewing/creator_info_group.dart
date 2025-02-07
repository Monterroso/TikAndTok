import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/video.dart';
import '../../services/firestore_service.dart';
import '../../screens/user_profile_screen.dart';

/// CreatorInfoGroup shows details about the video creator such as profile picture,
/// follow button, username, and video title. It is positioned at the bottom-left.
class CreatorInfoGroup extends StatelessWidget {
  final Video? video;

  const CreatorInfoGroup({
    Key? key,
    this.video,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (video == null) {
      return const _LoadingCreatorInfo();
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    // Don't show follow button on own videos
    final isOwnVideo = currentUserId == video!.userId;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().streamUserProfile(video!.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _LoadingCreatorInfo();
        }

        if (snapshot.hasError) {
          return _ErrorCreatorInfo(
            error: 'Error loading creator profile: ${snapshot.error}',
          );
        }

        final userData = snapshot.data!.data();
        if (userData == null) {
          return _ErrorCreatorInfo(
            error: 'Creator profile not found. The user may have been deleted.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: video!.userId,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24.0,
                    backgroundImage: userData['photoURL']?.isNotEmpty == true
                        ? NetworkImage(userData['photoURL']!)
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: userData['photoURL']?.isNotEmpty != true
                        ? const Icon(Icons.person, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(width: 8.0),
                if (!isOwnVideo) ...[
                  StreamBuilder<bool>(
                    stream: Stream.fromFuture(
                      FirestoreService().isFollowing(
                        followerId: currentUserId,
                        followedId: video!.userId,
                      ),
                    ),
                    builder: (context, followSnapshot) {
                      final isFollowing = followSnapshot.data ?? false;
                      
                      return ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirestoreService().toggleFollow(
                              followerId: currentUserId,
                              followedId: video!.userId,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing 
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isFollowing ? 'Following' : 'Follow'),
                            if (userData['followerCount'] != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${userData['followerCount']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              userData['username'] ?? userData['displayName'] ?? 'Unknown Creator',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              video!.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (video!.description.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                video!.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LoadingCreatorInfo extends StatelessWidget {
  const _LoadingCreatorInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              width: 80.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Container(
          width: 120.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        const SizedBox(height: 4.0),
        Container(
          width: 200.0,
          height: 14.0,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ],
    );
  }
}

class _ErrorCreatorInfo extends StatelessWidget {
  final String error;

  const _ErrorCreatorInfo({required this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8.0),
            const Text(
              'Error',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          error,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
} 