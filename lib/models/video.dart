import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  /// Creates a Video instance from a Firestore document
  factory Video.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      url: data['url'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  /// Converts the Video instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'userId': userId,
      'title': title,
      'description': description,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
