import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/controllers/video_collection_manager.dart';
import 'package:flutter_application_1/models/video.dart';
import 'video_collection_manager_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  group('VideoCollectionManager Tests', () {
    late MockFirestoreService mockFirestoreService;
    late VideoCollectionManager manager;
    final testUserId = 'test-user-id';

    final testVideo1 = Video(
      id: 'video1',
      url: 'https://example.com/video1.mp4',
      userId: 'creator1',
      title: 'Test Video 1',
      description: 'First test video',
      createdAt: DateTime.now(),
      metadata: {'category': 'DM Tips'},
    );

    final testVideo2 = Video(
      id: 'video2',
      url: 'https://example.com/video2.mp4',
      userId: 'creator2',
      title: 'Test Video 2',
      description: 'Second test video',
      createdAt: DateTime.now(),
      metadata: {'category': 'Player Highlights'},
    );

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      manager = VideoCollectionManager(firestoreService: mockFirestoreService);
    });

    test('initial state is empty', () {
      expect(manager.likedVideos, isEmpty);
      expect(manager.savedVideos, isEmpty);
      expect(manager.isLoadingLiked, isFalse);
      expect(manager.isLoadingSaved, isFalse);
      expect(manager.error, isNull);
    });

    test('fetchLikedVideos updates state correctly', () async {
      // Create a controller to manage the stream
      final controller = StreamController<List<Video>>();
      
      // Setup mock stream
      when(mockFirestoreService.streamLikedVideos(userId: testUserId))
          .thenAnswer((_) => controller.stream);

      // Start fetching
      final future = manager.fetchLikedVideos(testUserId);
      
      // Verify loading state was set
      expect(manager.isLoadingLiked, isTrue);
      
      // Add videos to stream
      controller.add([testVideo1, testVideo2]);
      
      // Wait for stream to emit and state to update
      await future;
      await Future.delayed(Duration.zero);
      
      // Verify final state
      expect(manager.likedVideos, hasLength(2));
      expect(manager.likedVideos.first.id, equals('video1'));
      expect(manager.isLoadingLiked, isFalse);
      expect(manager.error, isNull);

      // Clean up
      await controller.close();
    });

    test('fetchSavedVideos updates state correctly', () async {
      // Create a controller to manage the stream
      final controller = StreamController<List<Video>>();
      
      // Setup mock stream
      when(mockFirestoreService.streamSavedVideos(userId: testUserId))
          .thenAnswer((_) => controller.stream);

      // Start fetching
      final future = manager.fetchSavedVideos(testUserId);
      
      // Verify loading state was set
      expect(manager.isLoadingSaved, isTrue);
      
      // Add video to stream
      controller.add([testVideo1]);
      
      // Wait for stream to emit and state to update
      await future;
      await Future.delayed(Duration.zero);
      
      // Verify final state
      expect(manager.savedVideos, hasLength(1));
      expect(manager.savedVideos.first.id, equals('video1'));
      expect(manager.isLoadingSaved, isFalse);
      expect(manager.error, isNull);

      // Clean up
      await controller.close();
    });

    test('toggleSaveVideo handles save correctly', () async {
      // Create controllers for the streams
      final savedController = StreamController<List<Video>>();
      final likedController = StreamController<List<Video>>();
      
      // Setup mock streams
      when(mockFirestoreService.streamSavedVideos(userId: testUserId))
          .thenAnswer((_) => savedController.stream);
      when(mockFirestoreService.streamLikedVideos(userId: testUserId))
          .thenAnswer((_) => likedController.stream);
          
      // Setup toggle mock
      when(mockFirestoreService.toggleSave(
        videoId: testVideo1.id,
        userId: testUserId,
      )).thenAnswer((_) => Future.value());

      // Initialize with empty saved videos
      savedController.add([]);
      await manager.fetchSavedVideos(testUserId);
      await Future.delayed(Duration.zero);

      // Initialize with test video in liked videos
      likedController.add([testVideo1]);
      await manager.fetchLikedVideos(testUserId);
      await Future.delayed(Duration.zero);

      // Toggle save
      await manager.toggleSaveVideo(testVideo1.id, testUserId);

      // Verify service was called
      verify(mockFirestoreService.toggleSave(
        videoId: testVideo1.id,
        userId: testUserId,
      )).called(1);

      // Clean up
      await savedController.close();
      await likedController.close();
    });

    test('toggleLikeVideo handles like correctly', () async {
      // Create controllers for the streams
      final savedController = StreamController<List<Video>>();
      final likedController = StreamController<List<Video>>();
      
      // Setup mock streams
      when(mockFirestoreService.streamSavedVideos(userId: testUserId))
          .thenAnswer((_) => savedController.stream);
      when(mockFirestoreService.streamLikedVideos(userId: testUserId))
          .thenAnswer((_) => likedController.stream);
          
      // Setup toggle mock
      when(mockFirestoreService.toggleLike(
        videoId: testVideo1.id,
        userId: testUserId,
      )).thenAnswer((_) => Future.value());

      // Initialize with empty liked videos
      likedController.add([]);
      await manager.fetchLikedVideos(testUserId);
      await Future.delayed(Duration.zero);

      // Initialize with test video in saved videos
      savedController.add([testVideo1]);
      await manager.fetchSavedVideos(testUserId);
      await Future.delayed(Duration.zero);

      // Toggle like
      await manager.toggleLikeVideo(testVideo1.id, testUserId);

      // Verify service was called
      verify(mockFirestoreService.toggleLike(
        videoId: testVideo1.id,
        userId: testUserId,
      )).called(1);

      // Clean up
      await savedController.close();
      await likedController.close();
    });

    test('filterVideosByCategory returns correct videos', () async {
      // Create a controller to manage the stream
      final controller = StreamController<List<Video>>();
      
      // Setup mock stream
      when(mockFirestoreService.streamSavedVideos(userId: testUserId))
          .thenAnswer((_) => controller.stream);

      // Start fetching and add test videos
      final future = manager.fetchSavedVideos(testUserId);
      controller.add([testVideo1, testVideo2]);
      
      // Wait for stream to emit and state to update
      await future;
      await Future.delayed(Duration.zero);

      // Filter by category
      final dmTipsVideos = manager.filterVideosByCategory('DM Tips');
      expect(dmTipsVideos, hasLength(1));
      expect(dmTipsVideos.first.id, equals('video1'));

      final playerHighlightsVideos = manager.filterVideosByCategory('Player Highlights');
      expect(playerHighlightsVideos, hasLength(1));
      expect(playerHighlightsVideos.first.id, equals('video2'));

      // Clean up
      await controller.close();
    });

    test('searchVideos returns correct videos', () async {
      // Create a controller to manage the stream
      final controller = StreamController<List<Video>>();
      
      // Setup mock stream
      when(mockFirestoreService.streamSavedVideos(userId: testUserId))
          .thenAnswer((_) => controller.stream);

      // Start fetching and add test videos
      final future = manager.fetchSavedVideos(testUserId);
      controller.add([testVideo1, testVideo2]);
      
      // Wait for stream to emit and state to update
      await future;
      await Future.delayed(Duration.zero);

      // Search by title
      final searchResults1 = manager.searchVideos('Video 1');
      expect(searchResults1, hasLength(1));
      expect(searchResults1.first.id, equals('video1'));

      // Search by description
      final searchResults2 = manager.searchVideos('Second');
      expect(searchResults2, hasLength(1));
      expect(searchResults2.first.id, equals('video2'));

      // Clean up
      await controller.close();
    });

    test('clearError clears error state', () async {
      // Create a controller to manage the stream
      final controller = StreamController<List<Video>>();
      
      // Setup mock stream to emit error
      when(mockFirestoreService.streamSavedVideos(userId: testUserId))
          .thenAnswer((_) => controller.stream);

      // Start fetching
      final future = manager.fetchSavedVideos(testUserId);
      
      // Add error to stream
      controller.addError('Test error');
      
      // Wait for error to be processed
      await future;
      await Future.delayed(Duration.zero);
      
      // Verify error state
      expect(manager.error, isNotNull);
      
      // Clear error
      manager.clearError();
      expect(manager.error, isNull);

      // Clean up
      await controller.close();
    });
  });
} 