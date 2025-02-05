import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';

/// Service class to handle all Firestore document operations related to user profiles.
/// This service is responsible for:
/// - CRUD operations on user documents
/// - Data validation
/// - Document field updates
/// 
/// It does NOT handle:
/// - File uploads (see FirebaseStorageService)
/// - Binary data
/// - Image processing
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

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
}
