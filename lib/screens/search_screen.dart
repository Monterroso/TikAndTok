import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart';
import '../controllers/search_video_feed_controller.dart';
import '../controllers/video_collection_manager.dart';
import '../models/search.dart';
import '../models/video.dart';
import '../widgets/video_viewing/video_grid.dart';
import 'video_viewing_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _SearchBar(),
      ),
      body: Consumer<SearchController>(
        builder: (context, controller, _) {
          final state = controller.state;
          
          if (state.query.isEmpty) {
            return _RecentSearches();
          }

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text('Error: ${state.error}'),
            );
          }

          return _SearchResults(state: state);
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchController>(
      builder: (context, controller, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search videos and users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onChanged: (query) {
                  context.read<SearchController>().search(query.toLowerCase());
                },
              ),
            ),
            if (controller.state.query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Searching for: "${controller.state.query}"',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentSearches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchController>(
      builder: (context, controller, _) {
        final recentSearches = controller.state.recentSearches;

        if (recentSearches.isEmpty) {
          return const Center(
            child: Text('No recent searches'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.clearRecentSearches(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  final search = recentSearches[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(search),
                    onTap: () => controller.search(search),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchResults extends StatelessWidget {
  final SearchState state;

  const _SearchResults({required this.state});

  void _navigateToVideo(BuildContext context, Video video, int index) {
    final manager = context.read<VideoCollectionManager>();
    final controller = SearchVideoFeedController(
      searchResults: state.videoResults,
      initialIndex: index,
      collectionManager: manager,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoViewingScreen(feedController: controller),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context, Map<String, dynamic> user) {
    // TODO: Implement user profile navigation
    debugPrint('Navigate to user profile: ${user['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (state.userResults.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.userResults.length,
                itemBuilder: (context, index) {
                  final user = state.userResults[index];
                  return GestureDetector(
                    onTap: () => _navigateToUserProfile(context, user),
                    child: _UserCard(user: user),
                  );
                },
              ),
            ),
          ),
        ],
        if (state.videoResults.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Videos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: VideoGrid(
              videos: state.videoResults,
              onVideoTap: (video, index) => _navigateToVideo(context, video, index),
            ),
          ),
        ],
        if (state.userResults.isEmpty && state.videoResults.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No results found'),
            ),
          ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user['photoURL'] != null && user['photoURL'].isNotEmpty
                ? NetworkImage(user['photoURL'])
                : null,
            child: user['photoURL'] == null || user['photoURL'].isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            '@${user['username'] ?? 'User'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
} 