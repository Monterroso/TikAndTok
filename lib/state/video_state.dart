import 'package:flutter/foundation.dart';
import '../models/video.dart';

/// Represents the UI state of a video including interaction states
@immutable
class VideoState {
  final String videoId;
  final bool isLiked;
  final bool isSaved;
  final DateTime lastUpdated;
  final Video? videoData;
  final bool isLoading;
  final String? error;

  const VideoState({
    required this.videoId,
    this.isLiked = false,
    this.isSaved = false,
    required this.lastUpdated,
    this.videoData,
    this.isLoading = false,
    this.error,
  });

  /// Creates a loading state
  factory VideoState.loading(String videoId) {
    return VideoState(
      videoId: videoId,
      lastUpdated: DateTime.now(),
      isLoading: true,
    );
  }

  /// Creates an error state
  factory VideoState.error(String videoId, String error) {
    return VideoState(
      videoId: videoId,
      lastUpdated: DateTime.now(),
      error: error,
    );
  }

  /// Creates a copy of the current state with updated fields
  VideoState copyWith({
    bool? isLiked,
    bool? isSaved,
    Video? videoData,
    bool? isLoading,
    String? error,
  }) {
    return VideoState(
      videoId: videoId,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      lastUpdated: DateTime.now(),
      videoData: videoData ?? this.videoData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Checks if the state is stale based on a given duration
  bool isStale(Duration threshold) {
    return DateTime.now().difference(lastUpdated) > threshold;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoState &&
        other.videoId == videoId &&
        other.isLiked == isLiked &&
        other.isSaved == isSaved &&
        other.lastUpdated == lastUpdated &&
        other.videoData == videoData &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        videoId,
        isLiked,
        isSaved,
        lastUpdated,
        videoData,
        isLoading,
        error,
      );

  @override
  String toString() {
    return 'VideoState(videoId: $videoId, isLiked: $isLiked, isSaved: $isSaved, '
        'lastUpdated: $lastUpdated, hasVideoData: ${videoData != null}, '
        'isLoading: $isLoading, error: $error)';
  }
} 