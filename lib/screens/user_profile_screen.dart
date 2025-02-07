import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_profile_controller.dart';
import '../models/user_profile.dart';
import '../models/video.dart';
import '../widgets/video_viewing/video_grid.dart';
import '../services/firestore_service.dart';
import 'user_videos_feed_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProfileController(
        userId: userId,
        firestoreService: FirestoreService(),
      ),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProfileController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${controller.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final profile = controller.profile;
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              slivers: [
                _ProfileAppBar(profile: profile),
                _ProfileStats(profile: profile),
                _ActionButtons(profile: profile),
                if (controller.videos.isEmpty && !controller.isLoadingVideos)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text('No videos yet'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: VideoGrid(
                      videos: controller.videos,
                      isLoading: controller.isLoadingVideos,
                      hasMore: controller.hasMoreVideos,
                      onLoadMore: controller.loadMoreVideos,
                      error: controller.error,
                      onRetry: () => controller.refresh(),
                      onVideoTap: (video, index) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserVideosFeedScreen(
                              userId: profile.id,
                              initialVideoIndex: index,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  final UserProfile profile;

  const _ProfileAppBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('@${profile.username}'),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (profile.photoURL.isNotEmpty)
              Image.network(
                profile.photoURL,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Colors.grey),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final UserProfile profile;

  const _ProfileStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.bio.isNotEmpty) ...[
              Text(
                profile.bio,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Videos',
                  value: profile.videoCount.toString(),
                ),
                _StatItem(
                  label: 'Followers',
                  value: profile.followerCount.toString(),
                ),
                _StatItem(
                  label: 'Following',
                  value: profile.followingCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final UserProfile profile;

  const _ActionButtons({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Consumer<UserProfileController>(
                builder: (context, controller, _) {
                  return ElevatedButton(
                    onPressed: controller.toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          profile.isFollowing ? Colors.grey : Colors.blue,
                    ),
                    child: Text(
                      profile.isFollowing ? 'Following' : 'Follow',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 