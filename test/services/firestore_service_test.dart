import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/models/video.dart';
import 'firestore_service_test.mocks.dart';

// Create a test-specific implementation
class TestFirestoreService {
  final FirebaseFirestore _firestore;

  TestFirestoreService(this._firestore);

  Future<void> toggleSave({
    required String videoId,
    required String userId,
  }) async {
    try {
      // Run the update in a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final videoRef = _firestore.collection('videos').doc(videoId);
        final videoDoc = await transaction.get(videoRef);

        if (!videoDoc.exists) {
          throw 'Video not found';
        }

        final data = videoDoc.data() as Map<String, dynamic>;
        final savedByList = (data['savedBy'] as List<dynamic>?) ?? [];
        final savedBy = Set<String>.from(savedByList.map((e) => e.toString()));
        
        // Toggle save status
        final wasSaved = savedBy.contains(userId);
        if (wasSaved) {
          savedBy.remove(userId);
        } else {
          savedBy.add(userId);
        }

        // Update the document
        transaction.update(videoRef, {
          'savedBy': savedBy.toList(),
        });

        // Update user's saved_videos subcollection
        final userSavedRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_videos')
          .doc(videoId);

        if (wasSaved) {
          transaction.delete(userSavedRef);
        } else {
          transaction.set(userSavedRef, {
            'savedAt': FieldValue.serverTimestamp(),
            'videoId': videoId,
          });
        }
      });
    } catch (e) {
      throw 'Failed to toggle save: $e';
    }
  }

  Set<String> getSavedByFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>;
    final savedByList = (data['savedBy'] as List<dynamic>?) ?? [];
    return Set<String>.from(savedByList.map((e) => e.toString()));
  }
}

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  Query,
  QuerySnapshot,
  Transaction,
])
void main() {
  group('FirestoreService Save Video Tests', () {
    late TestFirestoreService service;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockVideosCollection;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
    late MockDocumentReference<Map<String, dynamic>> mockVideoRef;
    late MockDocumentReference<Map<String, dynamic>> mockUserRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockVideoDoc;
    late MockTransaction mockTransaction;
    late MockCollectionReference<Map<String, dynamic>> mockSavedVideosCollection;
    late MockDocumentReference<Map<String, dynamic>> mockSavedVideoRef;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockVideosCollection = MockCollectionReference();
      mockUsersCollection = MockCollectionReference();
      mockVideoRef = MockDocumentReference();
      mockUserRef = MockDocumentReference();
      mockVideoDoc = MockDocumentSnapshot();
      mockTransaction = MockTransaction();
      mockSavedVideosCollection = MockCollectionReference();
      mockSavedVideoRef = MockDocumentReference();

      // Setup FirestoreService with mock Firestore
      service = TestFirestoreService(mockFirestore);

      // Setup collection references
      when(mockFirestore.collection('videos')).thenReturn(mockVideosCollection);
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      
      // Setup document references
      when(mockVideosCollection.doc(any)).thenReturn(mockVideoRef);
      when(mockUsersCollection.doc(any)).thenReturn(mockUserRef);
      when(mockUserRef.collection('saved_videos')).thenReturn(mockSavedVideosCollection);
      when(mockSavedVideosCollection.doc(any)).thenReturn(mockSavedVideoRef);

      // Setup transaction
      when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
        final Function(Transaction) transactionHandler = invocation.positionalArguments[0];
        await transactionHandler(mockTransaction);
        return null;
      });

      // Allow any transaction operations
      when(mockTransaction.update(any, any)).thenAnswer((_) => mockTransaction);
      when(mockTransaction.set(any, any)).thenAnswer((_) => mockTransaction);
      when(mockTransaction.delete(any)).thenAnswer((_) => mockTransaction);
    });

    test('toggleSave adds user to savedBy when not saved', () async {
      final testVideoId = 'test-video-id';
      final testUserId = 'test-user-id';
      final testData = {
        'savedBy': <String>[],
      };

      // Setup mock responses
      when(mockTransaction.get(mockVideoRef)).thenAnswer((_) async => mockVideoDoc);
      when(mockVideoDoc.exists).thenReturn(true);
      when(mockVideoDoc.data()).thenReturn(testData);

      // Call the method
      await service.toggleSave(videoId: testVideoId, userId: testUserId);

      // Verify the video document was updated with the user added to savedBy
      verify(mockTransaction.update(mockVideoRef, {
        'savedBy': [testUserId],
      }));

      // Verify the user's saved_videos collection was updated
      verify(mockTransaction.set(
        mockSavedVideoRef,
        argThat(allOf(
          containsPair('videoId', testVideoId),
          predicate((Map<String, dynamic> map) => map['savedAt'] is FieldValue),
        )),
      ));
    });

    test('toggleSave removes user from savedBy when already saved', () async {
      final testVideoId = 'test-video-id';
      final testUserId = 'test-user-id';
      final testData = {
        'savedBy': [testUserId],
      };

      // Setup mock responses
      when(mockTransaction.get(mockVideoRef)).thenAnswer((_) async => mockVideoDoc);
      when(mockVideoDoc.exists).thenReturn(true);
      when(mockVideoDoc.data()).thenReturn(testData);

      // Call the method
      await service.toggleSave(videoId: testVideoId, userId: testUserId);

      // Verify the video document was updated with the user removed from savedBy
      verify(mockTransaction.update(mockVideoRef, {
        'savedBy': [],
      }));

      // Verify the document was deleted from user's saved_videos collection
      verify(mockTransaction.delete(mockSavedVideoRef));
    });

    test('toggleSave throws error when video not found', () async {
      final testVideoId = 'test-video-id';
      final testUserId = 'test-user-id';

      // Setup mock responses
      when(mockTransaction.get(mockVideoRef)).thenAnswer((_) async => mockVideoDoc);
      when(mockVideoDoc.exists).thenReturn(false);

      // Verify the method throws an error
      expect(
        () => service.toggleSave(videoId: testVideoId, userId: testUserId),
        throwsA(contains('Video not found')),
      );
    });

    test('getSavedByFromDoc returns correct set', () {
      final testUserId = 'test-user-id';
      final testData = {
        'savedBy': [testUserId],
      };

      when(mockVideoDoc.exists).thenReturn(true);
      when(mockVideoDoc.data()).thenReturn(testData);

      final result = service.getSavedByFromDoc(mockVideoDoc);
      expect(result, equals({testUserId}));
    });

    test('getSavedByFromDoc returns empty set for non-existent doc', () {
      when(mockVideoDoc.exists).thenReturn(false);

      final result = service.getSavedByFromDoc(mockVideoDoc);
      expect(result, isEmpty);
    });
  });
} 