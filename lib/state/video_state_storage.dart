import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_state.dart';
import '../models/video.dart';

/// Handles persistence of video states to local storage
class VideoStateStorage {
  static const String _keyPrefix = 'video_state_';
  static const String _timestampKey = 'last_cleanup_timestamp';
  final SharedPreferences _prefs;

  VideoStateStorage(this._prefs);

  /// Creates a new instance of VideoStateStorage
  static Future<VideoStateStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return VideoStateStorage(prefs);
  }

  /// Saves a video state to local storage
  Future<void> saveVideoState(VideoState state) async {
    final stateMap = {
      'videoId': state.videoId,
      'isLiked': state.isLiked,
      'isSaved': state.isSaved,
      'lastUpdated': state.lastUpdated.toIso8601String(),
      'isLoading': state.isLoading,
      'error': state.error,
      if (state.videoData != null)
        'videoData': {
          'id': state.videoData!.id,
          'url': state.videoData!.url,
          'userId': state.videoData!.userId,
          'title': state.videoData!.title,
          'description': state.videoData!.description,
          'likes': state.videoData!.likes,
          'comments': state.videoData!.comments,
          'createdAt': state.videoData!.createdAt.toIso8601String(),
          if (state.videoData!.metadata != null)
            'metadata': state.videoData!.metadata,
          'likedBy': state.videoData!.likedBy.toList(),
          'savedBy': state.videoData!.savedBy.toList(),
        },
    };

    await _prefs.setString(
      _keyPrefix + state.videoId,
      jsonEncode(stateMap),
    );
  }

  /// Loads a video state from local storage
  Future<VideoState?> loadVideoState(String videoId) async {
    final json = _prefs.getString(_keyPrefix + videoId);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      
      Video? videoData;
      if (map.containsKey('videoData')) {
        final videoMap = map['videoData'] as Map<String, dynamic>;
        videoData = Video(
          id: videoMap['id'] as String,
          url: videoMap['url'] as String,
          userId: videoMap['userId'] as String,
          title: videoMap['title'] as String,
          description: videoMap['description'] as String,
          likes: videoMap['likes'] as int,
          comments: videoMap['comments'] as int,
          createdAt: DateTime.parse(videoMap['createdAt'] as String),
          metadata: videoMap['metadata'] as Map<String, dynamic>?,
          likedBy: Set<String>.from(videoMap['likedBy'] as List),
          savedBy: Set<String>.from(videoMap['savedBy'] as List),
        );
      }

      return VideoState(
        videoId: map['videoId'] as String,
        isLiked: map['isLiked'] as bool,
        isSaved: map['isSaved'] as bool,
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
        isLoading: map['isLoading'] as bool,
        error: map['error'] as String?,
        videoData: videoData,
      );
    } catch (e) {
      // If there's an error parsing, remove the corrupted data
      await _prefs.remove(_keyPrefix + videoId);
      return null;
    }
  }

  /// Removes a video state from local storage
  Future<void> removeVideoState(String videoId) async {
    await _prefs.remove(_keyPrefix + videoId);
  }

  /// Cleans up old video states based on a given threshold
  Future<void> cleanup(Duration threshold) async {
    final now = DateTime.now();
    final lastCleanup = DateTime.fromMillisecondsSinceEpoch(
      _prefs.getInt(_timestampKey) ?? 0,
    );

    // Only clean up once per day
    if (now.difference(lastCleanup) < const Duration(days: 1)) {
      return;
    }

    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final key in keys) {
      final json = _prefs.getString(key);
      if (json == null) continue;

      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final lastUpdated = DateTime.parse(map['lastUpdated'] as String);
        if (now.difference(lastUpdated) > threshold) {
          await _prefs.remove(key);
        }
      } catch (e) {
        // Remove corrupted data
        await _prefs.remove(key);
      }
    }

    await _prefs.setInt(_timestampKey, now.millisecondsSinceEpoch);
  }

  /// Returns all stored video states
  Future<List<VideoState>> loadAllVideoStates() async {
    final states = <VideoState>[];
    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));

    for (final key in keys) {
      final videoId = key.substring(_keyPrefix.length);
      final state = await loadVideoState(videoId);
      if (state != null) {
        states.add(state);
      }
    }

    return states;
  }
} 