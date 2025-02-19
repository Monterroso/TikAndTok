import 'package:flutter/material.dart' hide SearchController;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/video_viewing_screen.dart';
import 'controllers/video_collection_manager.dart';
import 'controllers/liked_videos_feed_controller.dart';
import 'controllers/home_feed_controller.dart';
import 'controllers/search_controller.dart';
import 'services/firestore_service.dart';
import 'services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.userChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),
        Provider<GeminiService>(
          create: (_) => GeminiService(FirebaseFirestore.instance),
        ),
      ],
      child: FutureBuilder<(VideoCollectionManager, SharedPreferences)>(
        future: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final manager = await VideoCollectionManager.create();
            await manager.initialize();
            return (manager, prefs);
          } catch (e) {
            debugPrint('Error initializing app: $e');
            rethrow;
          }
        }(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Error initializing app:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          final (manager, prefs) = snapshot.data!;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(
                value: manager,
              ),
              ProxyProvider<VideoCollectionManager, LikedVideosFeedController>(
                update: (context, manager, _) => LikedVideosFeedController(
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  collectionManager: manager,
                ),
              ),
              ChangeNotifierProvider<SearchController>(
                create: (_) => SearchController(
                  firestoreService: FirestoreService(),
                  prefs: prefs,
                ),
              ),
            ],
            child: MaterialApp(
              title: 'D&D TikTok',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<User?>(context);
    if (user == null) {
      return const LoginScreen();
    }

    final manager = context.read<VideoCollectionManager>();
    final homeFeedController = HomeFeedController(collectionManager: manager);
    return VideoViewingScreen(feedController: homeFeedController);
  }
}
