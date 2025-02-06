import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/state/video_state.dart';
import 'package:flutter_application_1/state/video_state_cache.dart';

void main() {
  group('VideoStateCache', () {
    late VideoStateCache cache;
    const maxSize = 3;
    final testVideoId1 = 'video1';
    final testVideoId2 = 'video2';
    final testVideoId3 = 'video3';
    final testVideoId4 = 'video4';

    setUp(() {
      cache = VideoStateCache(
        maxSize: maxSize,
        staleThreshold: const Duration(minutes: 5),
      );
    });

    VideoState createTestState(String videoId) {
      return VideoState(
        videoId: videoId,
        lastUpdated: DateTime.now(),
      );
    }

    test('initializes with correct parameters', () {
      expect(cache.maxSize, equals(maxSize));
      expect(cache.isEmpty, isTrue);
      expect(cache.size, equals(0));
      expect(cache.isFull, isFalse);
    });

    test('put adds video state to cache', () {
      final state = createTestState(testVideoId1);
      cache.put(state);

      expect(cache.size, equals(1));
      expect(cache.get(testVideoId1), equals(state));
    });

    test('get returns null for non-existent video', () {
      expect(cache.get(testVideoId1), isNull);
    });

    test('contains returns correct value', () {
      final state = createTestState(testVideoId1);
      cache.put(state);

      expect(cache.contains(testVideoId1), isTrue);
      expect(cache.contains(testVideoId2), isFalse);
    });

    test('remove deletes video state from cache', () {
      final state = createTestState(testVideoId1);
      cache.put(state);
      cache.remove(testVideoId1);

      expect(cache.contains(testVideoId1), isFalse);
      expect(cache.size, equals(0));
    });

    test('clear removes all video states', () {
      cache.put(createTestState(testVideoId1));
      cache.put(createTestState(testVideoId2));
      cache.clear();

      expect(cache.isEmpty, isTrue);
      expect(cache.size, equals(0));
    });

    test('enforces maximum size with LRU eviction', () {
      // Add up to maximum size
      cache.put(createTestState(testVideoId1));
      cache.put(createTestState(testVideoId2));
      cache.put(createTestState(testVideoId3));
      expect(cache.size, equals(maxSize));

      // Add one more, should evict oldest (testVideoId1)
      cache.put(createTestState(testVideoId4));
      expect(cache.size, equals(maxSize));
      expect(cache.contains(testVideoId1), isFalse);
      expect(cache.contains(testVideoId4), isTrue);
    });

    test('updates access order on get', () {
      cache.put(createTestState(testVideoId1));
      cache.put(createTestState(testVideoId2));
      cache.put(createTestState(testVideoId3));

      // Access testVideoId1, making it most recently used
      cache.get(testVideoId1);

      // Add new item, should evict testVideoId2 instead of testVideoId1
      cache.put(createTestState(testVideoId4));
      expect(cache.contains(testVideoId1), isTrue);
      expect(cache.contains(testVideoId2), isFalse);
      expect(cache.contains(testVideoId4), isTrue);
    });

    test('handles stale entries correctly', () {
      final staleCache = VideoStateCache(
        maxSize: maxSize,
        staleThreshold: const Duration(seconds: 0), // Everything is immediately stale
      );

      final state = createTestState(testVideoId1);
      staleCache.put(state);

      expect(staleCache.get(testVideoId1), isNull);
      expect(staleCache.contains(testVideoId1), isFalse);
    });

    test('clearStale removes only stale entries', () {
      final now = DateTime.now();
      final staleState = VideoState(
        videoId: testVideoId1,
        lastUpdated: now.subtract(const Duration(minutes: 10)),
      );
      final freshState = VideoState(
        videoId: testVideoId2,
        lastUpdated: now,
      );

      final cache = VideoStateCache(
        maxSize: maxSize,
        staleThreshold: const Duration(minutes: 5),
      );

      cache.put(staleState);
      cache.put(freshState);
      cache.clearStale();

      expect(cache.contains(testVideoId1), isFalse);
      expect(cache.contains(testVideoId2), isTrue);
    });

    test('values returns unmodifiable list of all states', () {
      cache.put(createTestState(testVideoId1));
      cache.put(createTestState(testVideoId2));

      final values = cache.values();
      expect(values.length, equals(2));
      expect(() => values.add(createTestState(testVideoId3)), throwsUnsupportedError);
    });

    test('notifies listeners on state changes', () {
      var notificationCount = 0;
      cache.addListener(() => notificationCount++);

      cache.put(createTestState(testVideoId1)); // +1
      cache.remove(testVideoId1); // +1
      cache.clear(); // No notification (cache was empty)
      cache.put(createTestState(testVideoId2)); // +1
      cache.put(createTestState(testVideoId2)); // +1 (update)

      expect(notificationCount, equals(4));
    });
  });
} 