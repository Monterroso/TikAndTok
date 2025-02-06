import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'video_state.dart';

/// A cache for video states implementing LRU (Least Recently Used) eviction policy
class VideoStateCache extends ChangeNotifier {
  final int maxSize;
  final LinkedHashMap<String, VideoState> _cache;
  final Duration _staleThreshold;

  VideoStateCache({
    this.maxSize = 100,
    Duration? staleThreshold,
  })  : _cache = LinkedHashMap(),
        _staleThreshold = staleThreshold ?? const Duration(minutes: 5);

  /// Returns the number of items in the cache
  int get size => _cache.length;

  /// Returns true if the cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Returns true if the cache is at maximum capacity
  bool get isFull => _cache.length >= maxSize;

  /// Gets a video state from the cache
  /// Returns null if not found or if the state is stale
  VideoState? get(String videoId) {
    final state = _cache[videoId];
    if (state == null) return null;

    // Check if the state is stale
    if (state.isStale(_staleThreshold)) {
      _cache.remove(videoId);
      notifyListeners();
      return null;
    }

    // Move to end (most recently used)
    _cache.remove(videoId);
    _cache[videoId] = state;
    return state;
  }

  /// Adds or updates a video state in the cache
  void put(VideoState state) {
    // Remove if exists (to update position)
    _cache.remove(state.videoId);

    // Evict oldest if at capacity
    if (isFull) {
      _cache.remove(_cache.keys.first);
    }

    // Add new state
    _cache[state.videoId] = state;
    notifyListeners();
  }

  /// Removes a video state from the cache
  void remove(String videoId) {
    if (_cache.remove(videoId) != null) {
      notifyListeners();
    }
  }

  /// Clears all stale entries from the cache
  void clearStale() {
    final staleKeys = _cache.entries
        .where((entry) => entry.value.isStale(_staleThreshold))
        .map((entry) => entry.key)
        .toList();

    if (staleKeys.isNotEmpty) {
      for (final key in staleKeys) {
        _cache.remove(key);
      }
      notifyListeners();
    }
  }

  /// Clears the entire cache
  void clear() {
    if (_cache.isNotEmpty) {
      _cache.clear();
      notifyListeners();
    }
  }

  /// Returns a list of all video states in the cache
  List<VideoState> values() {
    return List.unmodifiable(_cache.values);
  }

  /// Returns true if the cache contains a video state for the given ID
  bool contains(String videoId) {
    return _cache.containsKey(videoId);
  }

  @override
  String toString() {
    return 'VideoStateCache(size: $size, maxSize: $maxSize, '
        'staleThreshold: $_staleThreshold)';
  }
} 