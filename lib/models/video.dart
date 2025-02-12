import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'video.freezed.dart';
part 'video.g.dart';

/// Video orientation enum
enum VideoOrientation {
  portrait,  // 9:16 aspect ratio
  landscape, // 16:9 aspect ratio
}

/// Represents a video in the application.
/// This model handles video metadata and provides conversion to/from Firestore.
@freezed
class Video with _$Video {
  const Video._(); // Custom constructor for methods

  const factory Video({
    required String id,
    required String url,
    required String userId,
    required String title,
    required String description,
    String? thumbnailUrl,
    @Default(0) int likes,
    @Default(0) int comments,
    required DateTime createdAt,
    Map<String, dynamic>? metadata,
    @Default({}) Set<String> likedBy,
    @Default({}) Set<String> savedBy,
    @Default(VideoOrientation.portrait) VideoOrientation orientation,
  }) = _Video;

  /// Creates a Video instance from a Firestore document
  factory Video.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Validate required fields
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw FormatException('Video URL is required', doc.id);
    }

    // Validate URL format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw FormatException('Invalid video URL format', url);
    }

    // Validate required string fields
    final userId = data['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw FormatException('User ID is required', doc.id);
    }

    final title = data['title'] as String?;
    if (title == null || title.isEmpty) {
      throw FormatException('Title is required', doc.id);
    }

    // Validate timestamp
    final timestamp = data['createdAt'] as Timestamp?;
    if (timestamp == null) {
      throw FormatException('Creation timestamp is required', doc.id);
    }

    // Convert likedBy array from Firestore to Set
    final likedByList = (data['likedBy'] as List<dynamic>?) ?? [];
    final likedBy = Set<String>.from(likedByList.map((e) => e.toString()));

    // Convert savedBy array from Firestore to Set
    final savedByList = (data['savedBy'] as List<dynamic>?) ?? [];
    final savedBy = Set<String>.from(savedByList.map((e) => e.toString()));

    // Parse orientation from metadata or default to portrait
    VideoOrientation orientation = VideoOrientation.portrait;
    if (data['metadata'] != null && data['metadata']['orientation'] != null) {
      orientation = data['metadata']['orientation'] == 'landscape' 
        ? VideoOrientation.landscape 
        : VideoOrientation.portrait;
    }

    return Video(
      id: doc.id,
      url: url,
      userId: userId,
      title: title,
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      likes: likedBy.length, // Compute likes from likedBy set size
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      createdAt: timestamp.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      likedBy: likedBy,
      savedBy: savedBy,
      orientation: orientation,
    );
  }

  /// Converts the Video instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final baseMap = {
      'url': url,
      'userId': userId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'likedBy': likedBy.toList(), // Convert Set to List for Firestore
      'savedBy': savedBy.toList(), // Convert Set to List for Firestore
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Include orientation in metadata
    final videoMetadata = metadata ?? {};
    videoMetadata['orientation'] = orientation == VideoOrientation.landscape ? 'landscape' : 'portrait';

    return {
      ...baseMap,
      'metadata': videoMetadata,
    };
  }

  /// Check if the video URL is still valid
  Future<bool> isUrlValid() async {
    try {
      final uri = Uri.parse(url);
      final response = await http.head(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if a user has liked this video
  bool isLikedByUser(String userId) => likedBy.contains(userId);

  /// Get the total number of likes (computed from likedBy set)
  int get likeCount => likedBy.length;

  /// Check if a user has saved this video
  bool isSavedByUser(String userId) => savedBy.contains(userId);

  /// Get the total number of saves (computed from savedBy set)
  int get saveCount => savedBy.length;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}
