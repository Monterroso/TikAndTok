import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/state/video_state.dart';
import '../mocks/mock_video.dart';

void main() {
  group('VideoState', () {
    final testVideoId = 'test_video_id';
    final testVideo = createMockVideo(id: testVideoId);

    test('creates with required parameters', () {
      final state = VideoState(
        videoId: testVideoId,
        lastUpdated: DateTime.now(),
      );

      expect(state.videoId, equals(testVideoId));
      expect(state.isLiked, isFalse);
      expect(state.isSaved, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.videoData, isNull);
    });

    test('creates loading state', () {
      final state = VideoState.loading(testVideoId);

      expect(state.videoId, equals(testVideoId));
      expect(state.isLoading, isTrue);
      expect(state.error, isNull);
    });

    test('creates error state', () {
      final errorMessage = 'Test error';
      final state = VideoState.error(testVideoId, errorMessage);

      expect(state.videoId, equals(testVideoId));
      expect(state.error, equals(errorMessage));
      expect(state.isLoading, isFalse);
    });

    test('copyWith updates specified fields', () {
      final initialState = VideoState(
        videoId: testVideoId,
        lastUpdated: DateTime.now(),
      );

      final updatedState = initialState.copyWith(
        isLiked: true,
        isSaved: true,
        videoData: testVideo,
        isLoading: true,
        error: 'New error',
      );

      expect(updatedState.videoId, equals(initialState.videoId));
      expect(updatedState.isLiked, isTrue);
      expect(updatedState.isSaved, isTrue);
      expect(updatedState.videoData, equals(testVideo));
      expect(updatedState.isLoading, isTrue);
      expect(updatedState.error, equals('New error'));
      expect(updatedState.lastUpdated.isAfter(initialState.lastUpdated), isTrue);
    });

    test('copyWith maintains unspecified fields', () {
      final initialState = VideoState(
        videoId: testVideoId,
        lastUpdated: DateTime.now(),
        isLiked: true,
        isSaved: true,
      );

      final updatedState = initialState.copyWith(
        isLoading: true,
      );

      expect(updatedState.isLiked, equals(initialState.isLiked));
      expect(updatedState.isSaved, equals(initialState.isSaved));
      expect(updatedState.videoData, equals(initialState.videoData));
    });

    test('isStale returns correct value', () {
      final state = VideoState(
        videoId: testVideoId,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      expect(state.isStale(const Duration(minutes: 5)), isTrue);
      expect(state.isStale(const Duration(minutes: 15)), isFalse);
    });

    test('equals compares all fields', () {
      final now = DateTime.now();
      final state1 = VideoState(
        videoId: testVideoId,
        lastUpdated: now,
        isLiked: true,
        isSaved: true,
        videoData: testVideo,
      );

      final state2 = VideoState(
        videoId: testVideoId,
        lastUpdated: now,
        isLiked: true,
        isSaved: true,
        videoData: testVideo,
      );

      final state3 = VideoState(
        videoId: testVideoId,
        lastUpdated: now,
        isLiked: false,
        isSaved: true,
        videoData: testVideo,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('toString provides meaningful description', () {
      final state = VideoState(
        videoId: testVideoId,
        lastUpdated: DateTime.now(),
        isLiked: true,
        videoData: testVideo,
      );

      expect(state.toString(), contains(testVideoId));
      expect(state.toString(), contains('true')); // isLiked
      expect(state.toString(), contains('hasVideoData: true'));
    });
  });
} 