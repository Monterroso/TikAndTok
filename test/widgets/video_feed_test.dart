import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_application_1/widgets/video_viewing/video_feed.dart';
import 'package:flutter_application_1/controllers/video_feed_controller.dart';
import 'package:flutter_application_1/controllers/video_collection_manager.dart';
import 'package:flutter_application_1/models/video.dart';
import 'video_feed_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<VideoFeedController>(as: #MockVideoFeedController),
  MockSpec<VideoCollectionManager>(as: #MockVideoCollectionManager),
])
void main() {
  group('VideoFeed Widget', () {
    late MockVideoFeedController mockController;
    late MockVideoCollectionManager mockManager;
    late List<Video> testVideos;

    setUp(() {
      mockManager = MockVideoCollectionManager();
      mockController = MockVideoFeedController();
      
      // Setup default behavior
      when(mockController.feedTitle).thenReturn('Test Feed');
      when(mockController.showBackButton).thenReturn(false);
      when(mockController.hasMoreVideos).thenReturn(true);
      when(mockController.isLoading).thenReturn(false);
      when(mockController.error).thenReturn(null);
      when(mockController.collectionManager).thenReturn(mockManager);

      testVideos = List.generate(
        3,
        (i) => Video(
          id: 'test_video_$i',
          url: 'https://example.com/video_$i.mp4',
          userId: 'test_user',
          title: 'Test Video $i',
          description: 'Test Description $i',
          createdAt: DateTime.now(),
        ),
      );
    });

    testWidgets('shows loading indicator when no videos', (tester) async {
      when(mockController.getNextPage(any, any)).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeed(
              controller: mockController,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loads and displays videos', (tester) async {
      when(mockController.getNextPage(any, any))
          .thenAnswer((_) async => testVideos);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeed(
              controller: mockController,
              onVideoChanged: (video) {},
            ),
          ),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Should find PageView
      expect(find.byType(PageView), findsOneWidget);
      
      // Should find VideoBackground widgets
      expect(find.byType(GestureDetector), findsNWidgets(3));
    });

    testWidgets('handles video changes', (tester) async {
      Video? changedVideo;
      when(mockController.getNextPage(any, any))
          .thenAnswer((_) async => testVideos);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeed(
              controller: mockController,
              onVideoChanged: (video) {
                changedVideo = video;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial video should be the first one
      expect(changedVideo?.id, equals('test_video_0'));
    });

    testWidgets('loads more videos when near end', (tester) async {
      when(mockController.getNextPage(any, any))
          .thenAnswer((_) async => testVideos);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeed(
              controller: mockController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate scrolling to last video
      final pageView = find.byType(PageView);
      await tester.drag(pageView, const Offset(0, -600)); // Scroll down
      await tester.pumpAndSettle();

      // Verify that getNextPage was called more than once (initial + load more)
      verify(mockController.getNextPage(any, any)).called(greaterThan(1));
    });

    testWidgets('shows error message when controller has error', (tester) async {
      when(mockController.getNextPage(any, any))
          .thenAnswer((_) async => testVideos);
      when(mockController.error).thenReturn('Test error message');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeed(
              controller: mockController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test error message'), findsOneWidget);
    });
  });

  group('VideoFeed Widget UI Tests', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeed(
              controller: MockVideoFeedController(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Add more UI-focused tests here as needed
  });
} 