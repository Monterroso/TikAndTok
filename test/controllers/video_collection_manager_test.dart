import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/controllers/video_collection_manager.dart';
import 'package:flutter_application_1/models/video.dart';
import 'video_collection_manager_test.mocks.dart';
import 'package:flutter_application_1/state/video_state_cache.dart';
import 'package:flutter_application_1/state/video_state_storage.dart';
import 'package:flutter_application_1/state/video_state.dart';
import '../mocks/mock_video.dart';

@GenerateMocks([FirestoreService, VideoStateStorage])
void main() {
  group('VideoCollectionManager', () {
    late VideoCollectionManager manager;
    late MockFirestoreService mockFirestore;
    late MockVideoStateStorage mockStorage;
    late VideoStateCache cache;

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockStorage = MockVideoStateStorage();
      cache = VideoStateCache();
      manager = VideoCollectionManager(
        firestoreService: mockFirestore,
        cache: cache,
        storage: mockStorage,
      );
    });

    test('initializes by loading states from storage', () async {
      final testState = VideoState(
        videoId: 'test_id',
        lastUpdated: DateTime.now(),
        isLiked: true,
      );
      
      when(mockStorage.loadAllVideoStates())
          .thenAnswer((_) async => [testState]);

      await manager.initialize();

      verify(mockStorage.loadAllVideoStates()).called(1);
      expect(await manager.getVideoState('test_id'), equals(testState));
      expect(manager.error, isNull);
    });

    test('handles initialization error', () async {
      when(mockStorage.loadAllVideoStates())
          .thenThrow('Test error');

      await manager.initialize();

      expect(manager.error, contains('Failed to initialize'));
      expect(manager.isLoading, isFalse);
    });

    test('toggles like with optimistic update', () async {
      const videoId = 'test_id';
      const userId = 'test_user';

      // Setup initial state
      final initialState = VideoState(
        videoId: videoId,
        lastUpdated: DateTime.now(),
        isLiked: false,
      );
      cache.put(initialState);

      // Mock storage
      when(mockStorage.saveVideoState(argThat(isA<VideoState>())))
          .thenAnswer((_) async {});

      // Mock Firestore
      when(mockFirestore.toggleLike(
        videoId: videoId,
        userId: userId,
      )).thenAnswer((_) async {});

      // Toggle like
      await manager.toggleLikeVideo(videoId, userId);

      // Verify optimistic update
      final updatedState = await manager.getVideoState(videoId);
      expect(updatedState?.isLiked, isTrue);

      // Verify storage update
      verify(mockStorage.saveVideoState(argThat(isA<VideoState>()))).called(1);

      // Verify Firestore update
      verify(mockFirestore.toggleLike(
        videoId: videoId,
        userId: userId,
      )).called(1);
    });

    test('reverts optimistic update on error', () async {
      const videoId = 'test_id';
      const userId = 'test_user';

      // Setup initial state
      final initialState = VideoState(
        videoId: videoId,
        lastUpdated: DateTime.now(),
        isLiked: false,
      );
      cache.put(initialState);

      // Mock storage
      when(mockStorage.saveVideoState(argThat(isA<VideoState>())))
          .thenAnswer((_) async {});

      // Mock Firestore error
      when(mockFirestore.toggleLike(
        videoId: videoId,
        userId: userId,
      )).thenThrow('Test error');

      // Toggle like
      await manager.toggleLikeVideo(videoId, userId);

      // Verify state was reverted
      final updatedState = await manager.getVideoState(videoId);
      expect(updatedState?.isLiked, isFalse);
      expect(updatedState?.error, contains('Failed to toggle like'));
    });

    test('gets liked videos and updates cache', () async {
      const userId = 'test_user';
      final testVideo = createMockVideo();

      when(mockFirestore.getLikedVideos(userId))
          .thenAnswer((_) async => [testVideo]);
      when(mockStorage.saveVideoState(argThat(isA<VideoState>())))
          .thenAnswer((_) async {});
      when(mockStorage.loadVideoState(testVideo.id))
          .thenAnswer((_) async => VideoState(
                videoId: testVideo.id,
                lastUpdated: DateTime.now(),
                isLiked: true,
                videoData: testVideo,
              ));

      final videos = await manager.getLikedVideos(userId);

      expect(videos.length, equals(1));
      expect(videos.first.id, equals(testVideo.id));

      // Verify cache was updated
      final cachedState = await manager.getVideoState(testVideo.id);
      expect(cachedState?.isLiked, isTrue);
      expect(cachedState?.videoData?.id, equals(testVideo.id));
    });

    test('gets saved videos and updates cache', () async {
      const userId = 'test_user';
      final testVideo = createMockVideo();

      when(mockFirestore.getSavedVideos(userId))
          .thenAnswer((_) async => [testVideo]);
      when(mockStorage.saveVideoState(argThat(isA<VideoState>())))
          .thenAnswer((_) async {});
      when(mockStorage.loadVideoState(testVideo.id))
          .thenAnswer((_) async => VideoState(
                videoId: testVideo.id,
                lastUpdated: DateTime.now(),
                isSaved: true,
                videoData: testVideo,
              ));

      final videos = await manager.getSavedVideos(userId);

      expect(videos.length, equals(1));
      expect(videos.first.id, equals(testVideo.id));

      // Verify cache was updated
      final cachedState = await manager.getVideoState(testVideo.id);
      expect(cachedState?.isSaved, isTrue);
      expect(cachedState?.videoData?.id, equals(testVideo.id));
    });

    test('performs cleanup', () async {
      when(mockStorage.cleanup(any))
          .thenAnswer((_) async {});

      await manager.cleanup();

      verify(mockStorage.cleanup(const Duration(days: 7))).called(1);
      expect(manager.error, isNull);
    });

    test('handles cleanup error', () async {
      when(mockStorage.cleanup(const Duration(days: 7)))
          .thenThrow('Test error');

      await manager.cleanup();

      expect(manager.error, contains('Failed to cleanup'));
    });
  });
} 