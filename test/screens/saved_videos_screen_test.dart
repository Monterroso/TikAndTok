import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/saved_videos_screen.dart';
import 'package:flutter_application_1/controllers/video_collection_manager.dart';
import 'package:flutter_application_1/models/video.dart';
import '../helpers/firebase_mocks.dart';
import 'saved_videos_screen_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth, 
  User, 
  VideoCollectionManager,
])
void main() {
  setupFirebaseCoreMocks();

  group('SavedVideosScreen Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockVideoCollectionManager mockManager;

    final testVideo1 = Video(
      id: 'video1',
      url: 'https://example.com/video1.mp4',
      userId: 'creator1',
      title: 'Test Video 1',
      description: 'First test video',
      createdAt: DateTime.now(),
    );

    final testVideo2 = Video(
      id: 'video2',
      url: 'https://example.com/video2.mp4',
      userId: 'creator2',
      title: 'Test Video 2',
      description: 'Second test video',
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockManager = MockVideoCollectionManager();

      // Setup default auth behavior
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');

      // Setup default manager behavior
      when(mockManager.likedVideos).thenReturn([testVideo1]);
      when(mockManager.savedVideos).thenReturn([testVideo2]);
      when(mockManager.isLoadingLiked).thenReturn(false);
      when(mockManager.isLoadingSaved).thenReturn(false);
      when(mockManager.error).thenReturn(null);
    });

    testWidgets('renders tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Verify tabs are present
      expect(find.text('Liked'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('displays liked videos in first tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify liked video is displayed
      expect(find.text('Test Video 1'), findsOneWidget);
    });

    testWidgets('displays saved videos in second tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Tap the Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      // Verify saved video is displayed
      expect(find.text('Test Video 2'), findsOneWidget);
    });

    testWidgets('handles loading state correctly', (WidgetTester tester) async {
      when(mockManager.isLoadingLiked).thenReturn(true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('handles error state correctly', (WidgetTester tester) async {
      when(mockManager.error).thenReturn('Test error message');
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Verify error message is shown
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('handles empty state correctly', (WidgetTester tester) async {
      when(mockManager.likedVideos).thenReturn([]);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Verify empty state message is shown
      expect(find.text('No liked videos yet'), findsOneWidget);
    });

    testWidgets('calls toggleLikeVideo when removing from liked tab', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Find and tap the remove button
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      // Verify toggleLikeVideo was called
      verify(mockManager.toggleLikeVideo('video1', 'test-user-id')).called(1);
    });

    testWidgets('calls toggleSaveVideo when removing from saved tab', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<FirebaseAuth>.value(value: mockAuth),
              ChangeNotifierProvider<VideoCollectionManager>.value(
                value: mockManager,
              ),
            ],
            child: const SavedVideosScreen(),
          ),
        ),
      );

      // Navigate to saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      // Find and tap the remove button
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      // Verify toggleSaveVideo was called
      verify(mockManager.toggleSaveVideo('video2', 'test-user-id')).called(1);
    });
  });
} 