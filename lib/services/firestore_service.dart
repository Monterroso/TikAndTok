import 'package:cloud_firestore/cloud_firestore.dart';

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
}
