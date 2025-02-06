import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_application_1/controllers/video_collection_manager.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'app_test.mocks.dart';
import 'helpers/firebase_mocks.dart';

@GenerateMocks([FirebaseAuth, User, FirestoreService])
void main() {
  setupFirebaseCoreMocks();

  group('App Provider Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestoreService = MockFirestoreService();
      
      // Setup default auth behavior
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      when(mockFirebaseAuth.userChanges())
          .thenAnswer((_) => Stream.value(null));
    });

    testWidgets('VideoCollectionManager is provided to widget tree', 
        (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            StreamProvider<User?>.value(
              value: mockFirebaseAuth.userChanges(),
              initialData: mockFirebaseAuth.currentUser,
            ),
            Provider<FirestoreService>.value(
              value: mockFirestoreService,
            ),
            ChangeNotifierProxyProvider<FirestoreService, VideoCollectionManager>(
              create: (_) => VideoCollectionManager(firestoreService: mockFirestoreService),
              update: (_, service, previous) => 
                previous ?? VideoCollectionManager(firestoreService: service),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Text('Test'),
            ),
          ),
        ),
      );

      // Verify VideoCollectionManager is available in the widget tree
      expect(
        Provider.of<VideoCollectionManager>(
          tester.element(find.text('Test')),
          listen: false,
        ),
        isA<VideoCollectionManager>(),
      );
    });

    testWidgets('VideoCollectionManager is lazily initialized', 
        (WidgetTester tester) async {
      var isCreated = false;

      // Build our app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            StreamProvider<User?>.value(
              value: mockFirebaseAuth.userChanges(),
              initialData: mockFirebaseAuth.currentUser,
            ),
            Provider<FirestoreService>.value(
              value: mockFirestoreService,
            ),
            ChangeNotifierProxyProvider<FirestoreService, VideoCollectionManager>(
              create: (_) {
                isCreated = true;
                return VideoCollectionManager(firestoreService: mockFirestoreService);
              },
              update: (_, service, previous) => 
                previous ?? VideoCollectionManager(firestoreService: service),
              lazy: true,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Text('Test'),
            ),
          ),
        ),
      );

      // Verify the provider hasn't been created yet
      expect(isCreated, false);

      // Access the provider
      Provider.of<VideoCollectionManager>(
        tester.element(find.text('Test')),
        listen: false,
      );

      // Verify the provider was created after being accessed
      expect(isCreated, true);
    });

    testWidgets('VideoCollectionManager persists across rebuilds', 
        (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            StreamProvider<User?>.value(
              value: mockFirebaseAuth.userChanges(),
              initialData: mockFirebaseAuth.currentUser,
            ),
            Provider<FirestoreService>.value(
              value: mockFirestoreService,
            ),
            ChangeNotifierProxyProvider<FirestoreService, VideoCollectionManager>(
              create: (_) => VideoCollectionManager(firestoreService: mockFirestoreService),
              update: (_, service, previous) => 
                previous ?? VideoCollectionManager(firestoreService: service),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Text('Test'),
            ),
          ),
        ),
      );

      // Get initial instance
      final initialInstance = Provider.of<VideoCollectionManager>(
        tester.element(find.text('Test')),
        listen: false,
      );

      // Trigger a rebuild
      await tester.pump();

      // Get instance after rebuild
      final newInstance = Provider.of<VideoCollectionManager>(
        tester.element(find.text('Test')),
        listen: false,
      );

      // Verify it's the same instance
      expect(identical(initialInstance, newInstance), true);
    });
  });
} 