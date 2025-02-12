import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
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
  static const String _videosPath = 'videos';
  static const int _maxFileSizeBytes = 100 * 1024 * 1024; // 100MB for videos
  static const double _maxAspectRatioTolerance = 0.1; // 10% tolerance for aspect ratio

  /// Validates video dimensions and orientation
  /// Returns null if valid, error message if invalid
  Future<String?> validateVideo(File file) async {
    try {
      // Check file size
      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        return 'Video file size must be less than ${_maxFileSizeBytes ~/ (1024 * 1024)}MB';
      }

      // Initialize video player to get dimensions
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      try {
        final size = controller.value.size;
        final aspectRatio = size.width / size.height;

        // Check if video dimensions are reasonable
        if (size.width < 180 || size.height < 180) {
          return 'Video dimensions too small. Minimum 180x180 pixels required.';
        }

        // Check if aspect ratio is close to portrait (9:16) or landscape (16:9)
        final portraitRatio = 9.0 / 16.0;
        final landscapeRatio = 16.0 / 9.0;
        
        final isPortraitLike = (aspectRatio - portraitRatio).abs() < _maxAspectRatioTolerance;
        final isLandscapeLike = (aspectRatio - landscapeRatio).abs() < _maxAspectRatioTolerance;

        if (!isPortraitLike && !isLandscapeLike) {
          return 'Video must be in portrait (9:16) or landscape (16:9) orientation';
        }

        return null;
      } finally {
        await controller.dispose();
      }
    } catch (e) {
      return 'Failed to validate video: $e';
    }
  }

  /// Uploads a video file to Firebase Storage
  /// Returns the download URL of the uploaded video
  Future<String> uploadVideo({
    required String uid,
    required File file,
    bool validateOrientation = true,
  }) async {
    try {
      if (validateOrientation) {
        final validationError = await validateVideo(file);
        if (validationError != null) {
          throw validationError;
        }
      }

      // Create a unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final filename = '$uid-$timestamp$extension';
      
      // Create a reference to the video location
      final ref = _storage.ref().child('$_videosPath/$filename');

      // Upload the video with metadata
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'video/${extension.substring(1)}',
          customMetadata: {
            'uploaded_by': uid,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get and return the download URL
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload video: $e';
    }
  }

  /// Uploads a profile image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    try {
      // Create a reference to the profile picture location
      final ref = _storage.ref().child('profile_pictures/$uid${path.extension(file.path)}');

      // Delete the old profile picture if it exists
      try {
        await ref.delete();
      } catch (e) {
        // Ignore error if file doesn't exist
      }

      // Upload the new image
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${path.extension(file.path).substring(1)}',
          customMetadata: {
            'uploaded_by': uid,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get and return the download URL
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }

  /// Deletes a file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: $e';
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
