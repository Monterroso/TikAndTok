import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/state/video_state_storage.dart';
import 'package:flutter_application_1/state/video_state.dart';
import '../mocks/mock_video.dart';

void main() {
  group('VideoStateStorage', () {
    late VideoStateStorage storage;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = VideoStateStorage(prefs);
    });

    test('saves and loads video state', () async {
      final video = createMockVideo();
      final state = VideoState(
        videoId: video.id,
        lastUpdated: DateTime.now(),
        isLiked: true,
        isSaved: true,
        videoData: video,
      );

      await storage.saveVideoState(state);
      final loadedState = await storage.loadVideoState(video.id);

      expect(loadedState, isNotNull);
      expect(loadedState!.videoId, equals(state.videoId));
      expect(loadedState.isLiked, equals(state.isLiked));
      expect(loadedState.isSaved, equals(state.isSaved));
      expect(loadedState.videoData?.id, equals(state.videoData?.id));
      expect(loadedState.videoData?.title, equals(state.videoData?.title));
    });

    test('returns null for non-existent video state', () async {
      final loadedState = await storage.loadVideoState('non_existent_id');
      expect(loadedState, isNull);
    });

    test('removes video state', () async {
      final video = createMockVideo();
      final state = VideoState(
        videoId: video.id,
        lastUpdated: DateTime.now(),
      );

      await storage.saveVideoState(state);
      await storage.removeVideoState(video.id);
      final loadedState = await storage.loadVideoState(video.id);

      expect(loadedState, isNull);
    });

    test('handles corrupted data gracefully', () async {
      // Save corrupted data directly to preferences
      await prefs.setString('video_state_corrupted', 'invalid json');
      
      final loadedState = await storage.loadVideoState('corrupted');
      expect(loadedState, isNull);
      
      // Verify corrupted data was cleaned up
      expect(prefs.getString('video_state_corrupted'), isNull);
    });

    test('cleanup removes old states', () async {
      final video1 = createMockVideo(id: 'recent');
      final video2 = createMockVideo(id: 'old');

      final recentState = VideoState(
        videoId: video1.id,
        lastUpdated: DateTime.now(),
        videoData: video1,
      );

      final oldState = VideoState(
        videoId: video2.id,
        lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
        videoData: video2,
      );

      await storage.saveVideoState(recentState);
      await storage.saveVideoState(oldState);

      await storage.cleanup(const Duration(days: 5));

      final loadedRecentState = await storage.loadVideoState(video1.id);
      final loadedOldState = await storage.loadVideoState(video2.id);

      expect(loadedRecentState, isNotNull);
      expect(loadedOldState, isNull);
    });

    test('loads all video states', () async {
      final states = [
        VideoState(
          videoId: 'video1',
          lastUpdated: DateTime.now(),
          videoData: createMockVideo(id: 'video1'),
        ),
        VideoState(
          videoId: 'video2',
          lastUpdated: DateTime.now(),
          videoData: createMockVideo(id: 'video2'),
        ),
      ];

      for (final state in states) {
        await storage.saveVideoState(state);
      }

      final loadedStates = await storage.loadAllVideoStates();
      expect(loadedStates.length, equals(states.length));
      expect(
        loadedStates.map((s) => s.videoId).toSet(),
        equals(states.map((s) => s.videoId).toSet()),
      );
    });
  });
} 