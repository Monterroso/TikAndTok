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
    String? username,
    String? photoURL,
  }) async {
    try {
      // Generate a default username if none provided
      final defaultUsername = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final baseUsername = username ?? defaultUsername;
      
      // Check if username exists and generate a unique one if needed
      String uniqueUsername = await _generateUniqueUsername(baseUsername);
      
      final userData = {
        'email': email,
        'username': uniqueUsername.toLowerCase(), // Store username in lowercase for case-insensitive matching
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

  /// Generates a unique username by appending numbers if necessary
  Future<String> _generateUniqueUsername(String baseUsername) async {
    String username = baseUsername;
    int counter = 1;
    bool isUnique = false;

    while (!isUnique) {
      // Check if username exists
      final query = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        isUnique = true;
      } else {
        // If username exists, append number and try again
        username = '$baseUsername$counter';
        counter++;
      }
    }

    return username;
  }

  /// Checks if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _usersCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  /// Updates specific fields of a user document
  /// Note: This method only stores the photoURL, it does not handle file uploads.
  /// Use FirebaseStorageService for handling profile picture uploads.
  Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? photoURL,
    String? bio,
  }) async {
    try {
      // Validate data if provided
      if (username != null) {
        final nameError = validateUsername(username);
        if (nameError != null) throw nameError;
        
        // Check if username is available (unless it's the same as current)
        final currentProfile = await getUserProfile(uid);
        if (currentProfile != null && 
            currentProfile['username'] != username && 
            !(await isUsernameAvailable(username))) {
          throw 'Username is already taken';
        }
      }
      
      if (bio != null) {
        final bioError = validateBio(bio);
        if (bioError != null) throw bioError;
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
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

        // Update both likedBy array and likes count atomically
        transaction.update(videoRef, {
          'likedBy': likedBy.toList(),
          'likes': likedBy.length, // Update likes count based on likedBy length
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
    if (!doc.exists) return {'comments': 0, 'likes': 0};
    final data = doc.data() as Map<String, dynamic>;
    return {
      'comments': data['comments'] as int? ?? 0,
      'likes': data['likes'] as int? ?? 0,
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
      final querySnapshot = await _firestore
          .collection('videos')
          .where('likedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc))
          .toList();
    } catch (e) {
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

  /// Fetches videos by their IDs
  /// Used for liked/saved video feeds where we have a list of IDs
  Future<List<Video>> getVideosByIds({
    required List<String> videoIds,
  }) async {
    try {
      if (videoIds.isEmpty) return [];

      // Firestore has a limit of 10 items for 'whereIn' queries
      // So we need to batch our requests if we have more than 10 IDs
      final batches = <Future<List<Video>>>[];
      for (var i = 0; i < videoIds.length; i += 10) {
        final end = (i + 10 < videoIds.length) ? i + 10 : videoIds.length;
        final batch = videoIds.sublist(i, end);
        
        batches.add(
          _videosCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get()
            .then((snapshot) => 
              snapshot.docs.map((doc) => Video.fromFirestore(doc)).toList()
            )
        );
      }

      final results = await Future.wait(batches);
      return results.expand((videos) => videos).toList();
    } catch (e) {
      throw 'Failed to fetch videos by IDs: $e';
    }
  }

  /// Fetches the next batch of filtered videos after the last video
  /// Used for paginated liked/saved video feeds
  Future<List<Video>> getNextFilteredVideos({
    required DocumentSnapshot lastVideo,
    required Set<String> filterIds,
    int limit = 10,
  }) async {
    try {
      if (filterIds.isEmpty) return [];

      final querySnapshot = await _videosCollection
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastVideo)
        .where(FieldPath.documentId, whereIn: filterIds.take(limit).toList())
        .limit(limit)
        .get();

      return querySnapshot.docs
        .map((doc) => Video.fromFirestore(doc))
        .toList();
    } catch (e) {
      throw 'Failed to fetch filtered videos: $e';
    }
  }

  /// Searches for videos by title
  Future<List<Video>> searchVideos(String query, {Video? startAfter, int limit = 10}) async {
    try {
      Query<Map<String, dynamic>> searchQuery = _videosCollection
          .orderBy('title')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + '\uf8ff')
          .limit(limit);

      if (startAfter != null) {
        final startAfterDoc = await _videosCollection.doc(startAfter.id).get();
        searchQuery = searchQuery.startAfterDocument(startAfterDoc);
      }

      final querySnapshot = await searchQuery.get();
      return querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching videos: $e');
      throw 'Failed to search videos: $e';
    }
  }

  /// Searches for users by username
  Future<List<Map<String, dynamic>>> searchUsers(String query, {DocumentSnapshot? startAfter, int limit = 10}) async {
    try {
      // Create query for username search
      Query<Map<String, dynamic>> usernameQuery = _usersCollection
          .orderBy('username')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + '\uf8ff')
          .limit(limit);

      if (startAfter != null) {
        usernameQuery = usernameQuery.startAfterDocument(startAfter);
      }

      // Execute query
      final querySnapshot = await usernameQuery.get();
      
      // Map results to include document ID
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      throw 'Failed to search users: $e';
    }
  }

  /// Gets videos by a specific user
  Future<List<Video>> getUserVideos({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    try {
      debugPrint('Querying videos for user: $userId, limit: $limit');
      
      Query<Map<String, dynamic>> query = _videosCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Video.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user videos: $e');
      if (e.toString().contains('failed-precondition') && 
          e.toString().contains('index')) {
        throw 'Database index for user videos is being built. Please try again in a few minutes. '
            'If the problem persists, please contact support.';
      }
      rethrow;
    }
  }

  /// Checks if a user is following another user
  Future<bool> isFollowing({
    required String followerId,
    required String followedId,
  }) async {
    try {
      final doc = await _usersCollection
          .doc(followedId)
          .collection('followers')
          .doc(followerId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Toggles follow status between two users
  Future<void> toggleFollow({
    required String followerId,
    required String followedId,
  }) async {
    if (followerId.isEmpty || followedId.isEmpty) {
      throw 'Invalid user IDs';
    }

    if (followerId == followedId) {
      throw 'Users cannot follow themselves';
    }

    try {
      // Run in a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final followedRef = _usersCollection.doc(followedId);
        final followerRef = _usersCollection.doc(followerId);
        final followerDoc = followedRef.collection('followers').doc(followerId);
        final followingDoc = followerRef.collection('following').doc(followedId);

        final isCurrentlyFollowing = (await transaction.get(followerDoc)).exists;

        if (isCurrentlyFollowing) {
          // Unfollow
          transaction.delete(followerDoc);
          transaction.delete(followingDoc);
          transaction.update(followedRef, {
            'followerCount': FieldValue.increment(-1),
          });
          transaction.update(followerRef, {
            'followingCount': FieldValue.increment(-1),
          });
        } else {
          // Follow
          final followData = {
            'userId': followerId,
            'timestamp': FieldValue.serverTimestamp(),
          };
          transaction.set(followerDoc, followData);
          transaction.set(followingDoc, followData);
          transaction.update(followedRef, {
            'followerCount': FieldValue.increment(1),
          });
          transaction.update(followerRef, {
            'followingCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      throw 'Failed to update follow status: $e';
    }
  }

  /// Gets a video document reference
  Future<DocumentSnapshot<Map<String, dynamic>>> getVideoDocument(String videoId) async {
    return await _videosCollection.doc(videoId).get();
  }

  /// Gets a list of user IDs that the specified user follows
  Future<List<String>> getFollowedUserIds(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  /// Gets videos from users that the specified user follows
  Future<List<Video>> getFollowingVideos(
    String userId, {
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    try {
      final followedUserIds = await getFollowedUserIds(userId);
      
      if (followedUserIds.isEmpty) {
        return [];
      }

      Query query = _videosCollection
          .where('userId', whereIn: followedUserIds)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting following videos: $e');
      rethrow;
    }
  }
}
