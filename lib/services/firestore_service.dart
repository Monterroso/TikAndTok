import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import '../models/comment.dart';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Service class to handle all Firestore document operations related to user profiles.
/// This service is responsible for:
/// - CRUD operations on user documents
/// - Data validation
/// - Document field updates
/// - Video interactions (likes, saves, comments)
/// 
/// It does NOT handle:
/// - File uploads (see FirebaseStorageService)
/// - Binary data
/// - Image processing
class FirestoreService {
  final FirebaseFirestore _firestore;
  
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal(FirebaseFirestore.instance);
  factory FirestoreService() => _instance;
  FirestoreService._internal(this._firestore);

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection => 
    _firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> get _videosCollection => 
    _firestore.collection('videos');

  /// Streams user profile document changes
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots();
  }

  /// Retrieves a user document from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.data();
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

  /// Creates a new user profile document
  /// This should be called when a new user signs up
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final userData = {
        'email': email,
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(uid).set(userData);
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  /// Updates specific fields of a user document
  /// Note: This method only stores the photoURL, it does not handle file uploads.
  /// Use FirebaseStorageService for handling profile picture uploads.
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? username,
    String? photoURL,
    String? bio,
  }) async {
    try {
      // Validate data if provided
      if (username != null) {
        final nameError = validateUsername(username);
        if (nameError != null) throw nameError;
      }
      if (bio != null) {
        final bioError = validateBio(bio);
        if (bioError != null) throw bioError;
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) updates['username'] = username;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (bio != null) updates['bio'] = bio;

      await _usersCollection.doc(uid).update(updates);
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  /// Validates username format and length
  String? validateUsername(String username) {
    if (username.length < 3 || username.length > 30) {
      return 'Username must be between 3 and 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  /// Validates bio length
  String? validateBio(String bio) {
    if (bio.length > 150) {
      return 'Bio must not exceed 150 characters';
    }
    return null;
  }

  /// Streams a list of videos for the feed
  /// Orders by creation date and limits the initial fetch
  Stream<List<Video>> streamVideos({int limit = 10}) {
    return _videosCollection
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => Video.fromFirestore(doc)).toList()
      );
  }

  /// Fetches the next batch of videos after the last video in the current feed
  Future<List<Video>> getNextVideos({
    required DocumentSnapshot lastVideo,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _videosCollection
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastVideo)
        .limit(limit)
        .get();

      return querySnapshot.docs
        .map((doc) => Video.fromFirestore(doc))
        .toList();
    } catch (e) {
      throw 'Failed to fetch next videos: $e';
    }
  }

  /// Creates a new video document in Firestore
  Future<String> createVideo({
    required String userId,
    required String url,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Verify the user exists before creating the video
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw 'Cannot create video: User profile does not exist';
      }

      final videoData = {
        'userId': userId,
        'url': url,
        'title': title,
        'description': description,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      };

      final docRef = await _videosCollection.add(videoData);
      return docRef.id;
    } catch (e) {
      throw 'Failed to create video document: $e';
    }
  }

  /// Updates video statistics (likes, comments)
  Future<void> updateVideoStats({
    required String videoId,
    int? likes,
    int? comments,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (likes != null) updates['likes'] = likes;
      if (comments != null) updates['comments'] = comments;

      await _videosCollection.doc(videoId).update(updates);
    } catch (e) {
      throw 'Failed to update video stats: $e';
    }
  }

  /// Toggles the like status of a video for a user
  Future<void> toggleLike({
    required String videoId,
    required String userId,
  }) async {
    try {
      // Run the update in a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final videoRef = _videosCollection.doc(videoId);
        final videoDoc = await transaction.get(videoRef);

        if (!videoDoc.exists) {
          throw 'Video not found';
        }

        final data = videoDoc.data() as Map<String, dynamic>;
        final likedByList = (data['likedBy'] as List<dynamic>?) ?? [];
        final likedBy = Set<String>.from(likedByList.map((e) => e.toString()));
        
        // Toggle like status
        final wasLiked = likedBy.contains(userId);
        if (wasLiked) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        // Update the document
        transaction.update(videoRef, {
          'likedBy': likedBy.toList(),
        });
      });
    } catch (e) {
      throw 'Failed to toggle like: $e';
    }
  }

  /// Stream of video document for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamVideoDocument(String videoId) {
    return _videosCollection.doc(videoId).snapshots();
  }

  /// Helper to get liked-by set from video document
  Set<String> getLikedByFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>;
    final likedByList = (data['likedBy'] as List<dynamic>?) ?? [];
    return Set<String>.from(likedByList.map((e) => e.toString()));
  }

  /// Helper to get video stats from document
  Map<String, dynamic> getStatsFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return {'likes': 0, 'comments': 0};
    final data = doc.data() as Map<String, dynamic>;
    return {
      'likes': data['likes'] ?? 0,
      'comments': data['comments'] ?? 0,
    };
  }

  /// Streams comments for a specific video
  Stream<List<Comment>> streamComments({required String videoId}) {
    return _videosCollection
        .doc(videoId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }

  /// Adds a new comment to a video
  Future<void> addComment({
    required String videoId,
    required String userId,
    required String message,
  }) async {
    try {
      // Verify user exists
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw 'Cannot add comment: User profile does not exist';
      }

      // Create the comment
      final commentData = {
        'videoId': videoId,
        'userId': userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Run in a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final videoRef = _videosCollection.doc(videoId);
        final videoDoc = await transaction.get(videoRef);

        if (!videoDoc.exists) {
          throw 'Video not found';
        }

        // Add the comment
        final commentsRef = videoRef.collection('comments');
        final newCommentRef = commentsRef.doc();
        transaction.set(newCommentRef, commentData);

        // Update video document with new comment count and timestamp
        transaction.update(videoRef, {
          'comments': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw 'Failed to add comment: $e';
    }
  }

  /// Deletes a comment from a video
  Future<void> deleteComment({
    required String videoId,
    required String commentId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final videoRef = _videosCollection.doc(videoId);
        final commentRef = videoRef.collection('comments').doc(commentId);
        
        // Verify comment exists and belongs to user
        final commentDoc = await transaction.get(commentRef);
        if (!commentDoc.exists) {
          throw 'Comment not found';
        }
        if (commentDoc.data()?['userId'] != userId) {
          throw 'Not authorized to delete this comment';
        }

        // Delete comment and update count atomically
        transaction.delete(commentRef);
        transaction.update(videoRef, {
          'comments': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw 'Failed to delete comment: $e';
    }
  }

  /// Helper to get saved-by set from video document
  Set<String> getSavedByFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>;
    final savedByList = (data['savedBy'] as List<dynamic>?) ?? [];
    return Set<String>.from(savedByList.map((e) => e.toString()));
  }

  /// Toggles the save status of a video for a user
  Future<void> toggleSave({
    required String videoId,
    required String userId,
  }) async {
    try {
      // Run the update in a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final videoRef = _videosCollection.doc(videoId);
        final videoDoc = await transaction.get(videoRef);

        if (!videoDoc.exists) {
          throw 'Video not found';
        }

        final data = videoDoc.data() as Map<String, dynamic>;
        final savedByList = (data['savedBy'] as List<dynamic>?) ?? [];
        final savedBy = Set<String>.from(savedByList.map((e) => e.toString()));
        
        // Toggle save status
        final wasSaved = savedBy.contains(userId);
        if (wasSaved) {
          savedBy.remove(userId);
        } else {
          savedBy.add(userId);
        }

        // Update the document
        transaction.update(videoRef, {
          'savedBy': savedBy.toList(),
        });

        // Update user's saved_videos subcollection
        final userSavedRef = _usersCollection
          .doc(userId)
          .collection('saved_videos')
          .doc(videoId);

        if (wasSaved) {
          transaction.delete(userSavedRef);
        } else {
          transaction.set(userSavedRef, {
            'savedAt': FieldValue.serverTimestamp(),
            'videoId': videoId,
          });
        }
      });
    } catch (e) {
      throw 'Failed to toggle save: $e';
    }
  }

  /// Streams saved videos for a user
  Stream<List<Video>> streamSavedVideos({required String userId}) {
    return _usersCollection
      .doc(userId)
      .collection('saved_videos')
      .orderBy('savedAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
        final videoIds = snapshot.docs.map((doc) => doc.id).toList();
        if (videoIds.isEmpty) return [];

        final videoSnapshots = await _videosCollection
          .where(FieldPath.documentId, whereIn: videoIds)
          .get();

        return videoSnapshots.docs
          .map((doc) => Video.fromFirestore(doc))
          .toList();
      });
  }

  /// Streams liked videos for a user
  Stream<List<Video>> streamLikedVideos({required String userId}) {
    return _videosCollection
      .where('likedBy', arrayContains: userId)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => Video.fromFirestore(doc)).toList()
      );
  }

  /// Gets all videos liked by a user
  Future<List<Video>> getLikedVideos(String userId) async {
    try {
      debugPrint('Fetching liked videos for user: $userId');
      final querySnapshot = await _firestore
          .collection('videos')
          .where('likedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} liked videos');
      return querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching liked videos: $e');
      if (e.toString().contains('failed-precondition') && 
          e.toString().contains('index')) {
        throw 'Database index for liked videos is being built. Please try again in a few minutes. '
            'If the problem persists, please contact support.';
      }
      throw 'Failed to get liked videos: $e';
    }
  }

  /// Gets all videos saved by a user
  Future<List<Video>> getSavedVideos(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('videos')
          .where('savedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (e.toString().contains('failed-precondition') && 
          e.toString().contains('index')) {
        throw 'Database index is being built. Please try again in a few minutes. '
            'If the problem persists, please contact support.';
      }
      throw 'Failed to get saved videos: $e';
    }
  }
}
