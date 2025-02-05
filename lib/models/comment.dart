import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a comment on a video in the application.
/// This model handles comment data and provides conversion to/from Firestore.
class Comment {
  final String id;
  final String videoId;
  final String userId;
  final String username;
  final String? profilePictureUrl;
  final String message;
  final DateTime timestamp;

  const Comment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    required this.message,
    required this.timestamp,
  });

  /// Creates a Comment instance from a Firestore document
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Validate required fields
    final videoId = data['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) {
      throw FormatException('Video ID is required', doc.id);
    }

    final userId = data['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw FormatException('User ID is required', doc.id);
    }

    final username = data['username'] as String?;
    if (username == null || username.isEmpty) {
      throw FormatException('Username is required', doc.id);
    }

    final message = data['message'] as String?;
    if (message == null || message.isEmpty) {
      throw FormatException('Message is required', doc.id);
    }

    // Validate timestamp
    final timestamp = data['timestamp'] as Timestamp?;
    if (timestamp == null) {
      throw FormatException('Timestamp is required', doc.id);
    }

    return Comment(
      id: doc.id,
      videoId: videoId,
      userId: userId,
      username: username,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      message: message,
      timestamp: timestamp.toDate(),
    );
  }

  /// Converts the Comment instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'userId': userId,
      'username': username,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  /// Creates a copy of this Comment with the given fields replaced with the new values
  Comment copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? username,
    String? profilePictureUrl,
    String? message,
    DateTime? timestamp,
  }) {
    return Comment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 