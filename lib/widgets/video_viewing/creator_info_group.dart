import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/video.dart';
import '../../services/firestore_service.dart';

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
                CircleAvatar(
                  radius: 24.0,
                  backgroundImage: userData['photoURL']?.isNotEmpty == true
                      ? NetworkImage(userData['photoURL']!)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: userData['photoURL']?.isNotEmpty != true
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement follow functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Follow'),
                ),
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