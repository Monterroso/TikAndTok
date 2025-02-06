import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

typedef Callback = void Function(MethodCall call);

class MockFirebasePlatform extends Mock implements FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseAppPlatform();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform();
  }
}

class MockFirebaseAppPlatform extends Mock implements FirebaseAppPlatform {
  @override
  String get name => 'test';

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
      );
}

void setupFirebaseCoreMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create and set mock platform
  final platform = MockFirebasePlatform();
  Firebase.delegatePackingProperty = platform;
} 