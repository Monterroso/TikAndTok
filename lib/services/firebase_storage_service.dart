import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
/// Service class to handle all Firebase Storage file operations.
/// This service is responsible for:
/// - File uploads
/// - File deletions
/// - File URL management
/// - Storage-specific error handling
/// 
/// It does NOT handle:
/// - Document data (see FirestoreService)
/// - User profile data
/// - Data validation
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Singleton pattern
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  // Constants
  static const String _profilePicturesPath = 'profile_pictures';
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Uploads a profile picture for a user
  /// Returns the download URL of the uploaded image
  /// Throws an error if the file is too large or invalid
  Future<String> uploadProfilePicture({
    required String uid,
    required File imageFile,
  }) async {
    try {
      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > _maxFileSizeBytes) {
        throw 'File size exceeds 5MB limit';
      }

      // Create a reference to the profile picture location
      final String fileName = '$uid.jpg';
      final storageRef = _storage.ref().child('$_profilePicturesPath/$fileName');
      
      // Upload the file
      await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': uid,
          },
        ),
      );
      
      // Get and return the download URL
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      throw 'Failed to upload profile picture: ${e.message}';
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }

  /// Deletes a user's profile picture if it exists
  /// Returns silently if no picture exists
  Future<void> deleteProfilePicture(String uid) async {
    try {
      final String fileName = '$uid.jpg';
      final storageRef = _storage.ref().child('$_profilePicturesPath/$fileName');
      await storageRef.delete();
    } on FirebaseException catch (e) {
      // If the file doesn't exist, we can ignore the error
      if (e.code == 'object-not-found') return;
      throw 'Failed to delete profile picture: ${e.message}';
    } catch (e) {
      throw 'Failed to delete profile picture: $e';
    }
  }

  /// Gets the download URL for a user's profile picture
  /// Returns null if no picture exists
  Future<String?> getProfilePictureUrl(String uid) async {
    try {
      final String fileName = '$uid.jpg';
      final storageRef = _storage.ref().child('$_profilePicturesPath/$fileName');
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      // If the file doesn't exist, return null
      if (e.code == 'object-not-found') return null;
      throw 'Failed to get profile picture URL: ${e.message}';
    } catch (e) {
      throw 'Failed to get profile picture URL: $e';
    }
  }
}
