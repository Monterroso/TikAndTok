import 'package:flutter/material.dart';
import '../../models/video.dart';

/// A reusable grid view for displaying video thumbnails
/// Can be used in collections, search results, or any other video listing screen
class VideoGrid extends StatelessWidget {
  final List<Video> videos;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget Function(Video video)? actionBuilder;
  final String emptyStateMessage;
  final IconData emptyStateIcon;
  final void Function(Video video, int index)? onVideoTap;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool useSlivers;

  const VideoGrid({
    Key? key,
    required this.videos,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.actionBuilder,
    this.emptyStateMessage = 'No videos available',
    this.emptyStateIcon = Icons.videocam_off,
    this.onVideoTap,
    this.onLoadMore,
    this.hasMore = false,
    this.useSlivers = true,
  }) : super(key: key);

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          emptyStateIcon,
          size: 48,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          emptyStateMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, int index) {
    // Check if we need to load more videos
    if (index >= videos.length - 3 && onLoadMore != null && hasMore && !isLoading) {
      onLoadMore!();
    }

    // Show loading indicator at the bottom
    if (index == videos.length) {
      if (isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (index >= videos.length) {
      return const SizedBox.shrink();
    }

    final video = videos[index];
    return GestureDetector(
      onTap: () => onVideoTap?.call(video, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Use thumbnailUrl if available, otherwise show placeholder
          if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
            Image.network(
              video.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),
          if (actionBuilder != null)
            Positioned(
              right: 4,
              top: 4,
              child: actionBuilder!(video),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.white54,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Loading thumbnail...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!useSlivers) {
      if (error != null) {
        return Center(child: _buildErrorWidget());
      }

      if (isLoading && videos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (videos.isEmpty) {
        return Center(child: _buildEmptyWidget());
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 9 / 16,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: videos.length + (isLoading ? 1 : 0),
        itemBuilder: _buildGridItem,
      );
    }

    if (error != null) {
      return SliverToBoxAdapter(
        child: Center(child: _buildErrorWidget()),
      );
    }

    if (isLoading && videos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (videos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: _buildEmptyWidget()),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        _buildGridItem,
        childCount: videos.length + (isLoading ? 1 : 0),
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final Video video;
  final Widget Function(Video video)? actionBuilder;
  final VoidCallback? onTap;

  const VideoCard({
    Key? key,
    required this.video,
    this.actionBuilder,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder container with gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[800]!,
                    Colors.grey[900]!,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
            // Gradient overlay for better text visibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Video title
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Custom action (like remove button) - now on top
            if (actionBuilder != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: actionBuilder!(video),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 