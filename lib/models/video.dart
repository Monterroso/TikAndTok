import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Represents a video in the application.
/// This model handles video metadata and provides conversion to/from Firestore.
class Video {
  final String id;
  final String url;
  final String userId;
  final String title;
  final String description;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final Set<String> likedBy;
  final Set<String> savedBy;

  const Video({
    required this.id,
    required this.url,
    required this.userId,
    required this.title,
    required this.description,
    this.likes = 0,
    this.comments = 0,
    required this.createdAt,
    this.metadata,
    this.likedBy = const {},
    this.savedBy = const {},
  });

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

    return Video(
      id: doc.id,
      url: url,
      userId: userId,
      title: title,
      description: data['description'] ?? '',
      likes: likedBy.length, // Compute likes from likedBy set size
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      createdAt: timestamp.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      likedBy: likedBy,
      savedBy: savedBy,
    );
  }

  /// Converts the Video instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'userId': userId,
      'title': title,
      'description': description,
      'likedBy': likedBy.toList(), // Convert Set to List for Firestore
      'savedBy': savedBy.toList(), // Convert Set to List for Firestore
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      if (metadata != null) 'metadata': metadata,
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

  /// Create a copy of this Video with modified fields
  Video copyWith({
    String? id,
    String? url,
    String? userId,
    String? title,
    String? description,
    int? likes,
    int? comments,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    Set<String>? likedBy,
    Set<String>? savedBy,
  }) {
    return Video(
      id: id ?? this.id,
      url: url ?? this.url,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      likedBy: likedBy ?? this.likedBy,
      savedBy: savedBy ?? this.savedBy,
    );
  }
}
