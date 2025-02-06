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
  final VoidCallback? onVideoTap;

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
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
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Column(
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
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 9 / 16, // Video aspect ratio
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          actionBuilder: actionBuilder,
          onTap: onVideoTap,
        );
      },
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
    return Stack(
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
        // Custom action (like remove button)
        if (actionBuilder != null)
          Positioned(
            top: 8,
            right: 8,
            child: actionBuilder!(video),
          ),
        // Make the entire card tappable
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
          ),
        ),
      ],
    );
  }
} 