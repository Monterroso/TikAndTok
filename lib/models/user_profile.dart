import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const UserProfile._(); // Custom constructor for methods

  const factory UserProfile({
    required String id,
    required String username,
    required String photoURL,
    required String bio,
    required int videoCount,
    required int followerCount,
    required int followingCount,
    @Default(false) bool isFollowing,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  /// Creates a UserProfile instance from a Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile.fromMap(doc.id, data);
  }

  /// Creates a UserProfile instance from a map of data
  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      username: data['username'] as String? ?? '',
      photoURL: data['photoURL'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      videoCount: data['videoCount'] as int? ?? 0,
      followerCount: data['followerCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      isFollowing: false, // This will be set separately
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the UserProfile instance to a Map for Firestore
  Map<String, dynamic> toFirestore() => {
    'username': username,
    'photoURL': photoURL,
    'bio': bio,
    'videoCount': videoCount,
    'followerCount': followerCount,
    'followingCount': followingCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
} 