import 'package:flutter_application_1/models/video.dart';

/// Creates a mock Video instance for testing
Video createMockVideo({
  String id = 'test_id',
  String url = 'https://test.com/video.mp4',
  String userId = 'test_user_id',
  String title = 'Test Video',
  String description = 'Test Description',
  int likes = 0,
  int comments = 0,
  DateTime? createdAt,
  Map<String, dynamic>? metadata,
  Set<String>? likedBy,
  Set<String>? savedBy,
}) {
  return Video(
    id: id,
    url: url,
    userId: userId,
    title: title,
    description: description,
    likes: likes,
    comments: comments,
    createdAt: createdAt ?? DateTime.now(),
    metadata: metadata,
    likedBy: likedBy ?? {},
    savedBy: savedBy ?? {},
  );
} 