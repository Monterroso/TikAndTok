import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_application_1/models/video.dart';
import 'video_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('Video Model Tests', () {
    final testUserId = 'testUser123';
    final testVideoData = {
      'url': 'https://example.com/test.mp4',
      'userId': 'creator123',
      'title': 'Test Video',
      'description': 'Test description',
      'comments': 0,
      'createdAt': Timestamp.now(),
      'likedBy': <String>[],
      'savedBy': <String>[],
      'metadata': {'test': 'data'},
    };

    late MockDocumentSnapshot mockDoc;

    setUp(() {
      mockDoc = MockDocumentSnapshot();
      when(mockDoc.id).thenReturn('test-video-id');
      when(mockDoc.data()).thenReturn(testVideoData);
    });

    test('fromFirestore creates Video with empty savedBy', () {
      final video = Video.fromFirestore(mockDoc);
      expect(video.savedBy, isEmpty);
      expect(video.saveCount, equals(0));
    });

    test('fromFirestore creates Video with savedBy users', () {
      final dataWithSaves = Map<String, dynamic>.from(testVideoData)
        ..['savedBy'] = [testUserId];
      when(mockDoc.data()).thenReturn(dataWithSaves);
      
      final video = Video.fromFirestore(mockDoc);
      expect(video.savedBy, contains(testUserId));
      expect(video.saveCount, equals(1));
    });

    test('toFirestore includes savedBy as list', () {
      final video = Video.fromFirestore(mockDoc);
      final map = video.toFirestore();
      expect(map['savedBy'], isA<List<String>>());
      expect(map['savedBy'], isEmpty);
    });

    test('isSavedByUser returns correct boolean', () {
      final dataWithSaves = Map<String, dynamic>.from(testVideoData)
        ..['savedBy'] = [testUserId];
      when(mockDoc.data()).thenReturn(dataWithSaves);
      
      final video = Video.fromFirestore(mockDoc);
      expect(video.isSavedByUser(testUserId), isTrue);
      expect(video.isSavedByUser('otherUser'), isFalse);
    });

    test('saveCount returns correct number', () {
      final dataWithMultipleSaves = Map<String, dynamic>.from(testVideoData)
        ..['savedBy'] = ['user1', 'user2', 'user3'];
      when(mockDoc.data()).thenReturn(dataWithMultipleSaves);
      
      final video = Video.fromFirestore(mockDoc);
      expect(video.saveCount, equals(3));
    });

    test('copyWith updates savedBy correctly', () {
      final video = Video.fromFirestore(mockDoc);
      final updatedVideo = video.copyWith(savedBy: {'user1', 'user2'});
      
      expect(updatedVideo.savedBy, containsAll(['user1', 'user2']));
      expect(updatedVideo.saveCount, equals(2));
      // Verify other fields remain unchanged
      expect(updatedVideo.id, equals(video.id));
      expect(updatedVideo.url, equals(video.url));
      expect(updatedVideo.title, equals(video.title));
    });
  });
} 