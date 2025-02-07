import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../models/video.dart';

class UserProfileController extends ChangeNotifier {
  final String userId;
  final FirestoreService _firestoreService;
  final String _currentUserId;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  List<Video> _videos = [];
  bool _hasMoreVideos = true;
  bool _isLoadingVideos = false;

  UserProfileController({
    required this.userId,
    required FirestoreService firestoreService,
  })  : _firestoreService = firestoreService,
        _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '' {
    _loadProfile();
    _loadInitialVideos();
  }

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Video> get videos => _videos;
  bool get hasMoreVideos => _hasMoreVideos;
  bool get isLoadingVideos => _isLoadingVideos;

  Future<void> _loadProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get the user's profile data
      final profileData = await _firestoreService.getUserProfile(userId);
      if (profileData == null) {
        throw 'User profile not found';
      }

      // Check if the current user is following this profile
      final isFollowing = await _firestoreService.isFollowing(
        followerId: _currentUserId,
        followedId: userId,
      );

      // Create profile with follow status
      _profile = UserProfile.fromMap(userId, profileData).copyWith(
        isFollowing: isFollowing,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadInitialVideos() async {
    try {
      _isLoadingVideos = true;
      notifyListeners();

      final videos = await _firestoreService.getUserVideos(
        userId: userId,
        limit: 12,
      );

      _videos = videos;
      _hasMoreVideos = videos.length >= 12;
      _error = null;
    } catch (e) {
      debugPrint('Error loading videos: $e');
      if (e.toString().contains('index is being built')) {
        _error = 'Loading videos... Please wait a moment and try again.';
      } else {
        _error = 'Failed to load videos. Please try again.';
      }
    } finally {
      _isLoadingVideos = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreVideos() async {
    if (_isLoadingVideos || !_hasMoreVideos) return;

    try {
      _isLoadingVideos = true;
      notifyListeners();

      final lastVideo = _videos.lastOrNull;
      if (lastVideo == null) return;

      final lastVideoDoc = await _firestoreService.getVideoDocument(lastVideo.id);
      final moreVideos = await _firestoreService.getUserVideos(
        userId: userId,
        startAfter: lastVideoDoc,
        limit: 12,
      );

      _videos.addAll(moreVideos);
      _hasMoreVideos = moreVideos.length >= 12;
    } catch (e) {
      debugPrint('Error loading more videos: $e');
    } finally {
      _isLoadingVideos = false;
      notifyListeners();
    }
  }

  Future<void> toggleFollow() async {
    if (_profile == null) return;

    try {
      // Optimistically update UI
      _profile = _profile!.copyWith(
        isFollowing: !_profile!.isFollowing,
        followerCount: _profile!.followerCount + (_profile!.isFollowing ? -1 : 1),
      );
      notifyListeners();

      // Update in Firestore
      await _firestoreService.toggleFollow(
        followerId: _currentUserId,
        followedId: userId,
      );
    } catch (e) {
      // Revert on error
      _profile = _profile!.copyWith(
        isFollowing: !_profile!.isFollowing,
        followerCount: _profile!.followerCount + (_profile!.isFollowing ? 1 : -1),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadProfile(),
      _loadInitialVideos(),
    ]);
  }
} 