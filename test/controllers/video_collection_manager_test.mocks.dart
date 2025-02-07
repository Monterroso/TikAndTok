// Mocks generated by Mockito 5.4.5 from annotations
// in flutter_application_1/test/controllers/video_collection_manager_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:cloud_firestore/cloud_firestore.dart' as _i4;
import 'package:flutter_application_1/models/comment.dart' as _i7;
import 'package:flutter_application_1/models/video.dart' as _i5;
import 'package:flutter_application_1/services/firestore_service.dart' as _i2;
import 'package:flutter_application_1/state/video_state.dart' as _i9;
import 'package:flutter_application_1/state/video_state_storage.dart' as _i8;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [FirestoreService].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirestoreService extends _i1.Mock implements _i2.FirestoreService {
  MockFirestoreService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Stream<_i4.DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(
    String? uid,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#streamUserProfile, [uid]),
            returnValue:
                _i3.Stream<_i4.DocumentSnapshot<Map<String, dynamic>>>.empty(),
          )
          as _i3.Stream<_i4.DocumentSnapshot<Map<String, dynamic>>>);

  @override
  _i3.Future<Map<String, dynamic>?> getUserProfile(String? uid) =>
      (super.noSuchMethod(
            Invocation.method(#getUserProfile, [uid]),
            returnValue: _i3.Future<Map<String, dynamic>?>.value(),
          )
          as _i3.Future<Map<String, dynamic>?>);

  @override
  _i3.Future<void> createUserProfile({
    required String? uid,
    required String? email,
    String? displayName,
    String? photoURL,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#createUserProfile, [], {
              #uid: uid,
              #email: email,
              #displayName: displayName,
              #photoURL: photoURL,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> updateUserProfile({
    required String? uid,
    String? displayName,
    String? username,
    String? photoURL,
    String? bio,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#updateUserProfile, [], {
              #uid: uid,
              #displayName: displayName,
              #username: username,
              #photoURL: photoURL,
              #bio: bio,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  String? validateUsername(String? username) =>
      (super.noSuchMethod(Invocation.method(#validateUsername, [username]))
          as String?);

  @override
  String? validateBio(String? bio) =>
      (super.noSuchMethod(Invocation.method(#validateBio, [bio])) as String?);

  @override
  _i3.Stream<List<_i5.Video>> streamVideos({int? limit = 10}) =>
      (super.noSuchMethod(
            Invocation.method(#streamVideos, [], {#limit: limit}),
            returnValue: _i3.Stream<List<_i5.Video>>.empty(),
          )
          as _i3.Stream<List<_i5.Video>>);

  @override
  _i3.Future<List<_i5.Video>> getNextVideos({
    required _i4.DocumentSnapshot<Object?>? lastVideo,
    int? limit = 10,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#getNextVideos, [], {
              #lastVideo: lastVideo,
              #limit: limit,
            }),
            returnValue: _i3.Future<List<_i5.Video>>.value(<_i5.Video>[]),
          )
          as _i3.Future<List<_i5.Video>>);

  @override
  _i3.Future<String> createVideo({
    required String? userId,
    required String? url,
    required String? title,
    required String? description,
    Map<String, dynamic>? metadata,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#createVideo, [], {
              #userId: userId,
              #url: url,
              #title: title,
              #description: description,
              #metadata: metadata,
            }),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#createVideo, [], {
                  #userId: userId,
                  #url: url,
                  #title: title,
                  #description: description,
                  #metadata: metadata,
                }),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<void> updateVideoStats({
    required String? videoId,
    int? likes,
    int? comments,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#updateVideoStats, [], {
              #videoId: videoId,
              #likes: likes,
              #comments: comments,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> toggleLike({
    required String? videoId,
    required String? userId,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#toggleLike, [], {
              #videoId: videoId,
              #userId: userId,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Stream<_i4.DocumentSnapshot<Map<String, dynamic>>> streamVideoDocument(
    String? videoId,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#streamVideoDocument, [videoId]),
            returnValue:
                _i3.Stream<_i4.DocumentSnapshot<Map<String, dynamic>>>.empty(),
          )
          as _i3.Stream<_i4.DocumentSnapshot<Map<String, dynamic>>>);

  @override
  Set<String> getLikedByFromDoc(
    _i4.DocumentSnapshot<Map<String, dynamic>>? doc,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#getLikedByFromDoc, [doc]),
            returnValue: <String>{},
          )
          as Set<String>);

  @override
  Map<String, dynamic> getStatsFromDoc(
    _i4.DocumentSnapshot<Map<String, dynamic>>? doc,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#getStatsFromDoc, [doc]),
            returnValue: <String, dynamic>{},
          )
          as Map<String, dynamic>);

  @override
  _i3.Stream<List<_i7.Comment>> streamComments({required String? videoId}) =>
      (super.noSuchMethod(
            Invocation.method(#streamComments, [], {#videoId: videoId}),
            returnValue: _i3.Stream<List<_i7.Comment>>.empty(),
          )
          as _i3.Stream<List<_i7.Comment>>);

  @override
  _i3.Future<void> addComment({
    required String? videoId,
    required String? userId,
    required String? message,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#addComment, [], {
              #videoId: videoId,
              #userId: userId,
              #message: message,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> deleteComment({
    required String? videoId,
    required String? commentId,
    required String? userId,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#deleteComment, [], {
              #videoId: videoId,
              #commentId: commentId,
              #userId: userId,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  Set<String> getSavedByFromDoc(
    _i4.DocumentSnapshot<Map<String, dynamic>>? doc,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#getSavedByFromDoc, [doc]),
            returnValue: <String>{},
          )
          as Set<String>);

  @override
  _i3.Future<void> toggleSave({
    required String? videoId,
    required String? userId,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#toggleSave, [], {
              #videoId: videoId,
              #userId: userId,
            }),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Stream<List<_i5.Video>> streamSavedVideos({required String? userId}) =>
      (super.noSuchMethod(
            Invocation.method(#streamSavedVideos, [], {#userId: userId}),
            returnValue: _i3.Stream<List<_i5.Video>>.empty(),
          )
          as _i3.Stream<List<_i5.Video>>);

  @override
  _i3.Stream<List<_i5.Video>> streamLikedVideos({required String? userId}) =>
      (super.noSuchMethod(
            Invocation.method(#streamLikedVideos, [], {#userId: userId}),
            returnValue: _i3.Stream<List<_i5.Video>>.empty(),
          )
          as _i3.Stream<List<_i5.Video>>);

  @override
  _i3.Future<List<_i5.Video>> getLikedVideos(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#getLikedVideos, [userId]),
            returnValue: _i3.Future<List<_i5.Video>>.value(<_i5.Video>[]),
          )
          as _i3.Future<List<_i5.Video>>);

  @override
  _i3.Future<List<_i5.Video>> getSavedVideos(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#getSavedVideos, [userId]),
            returnValue: _i3.Future<List<_i5.Video>>.value(<_i5.Video>[]),
          )
          as _i3.Future<List<_i5.Video>>);

  @override
  _i3.Future<List<_i5.Video>> getVideosByIds({
    required List<String>? videoIds,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#getVideosByIds, [], {#videoIds: videoIds}),
            returnValue: _i3.Future<List<_i5.Video>>.value(<_i5.Video>[]),
          )
          as _i3.Future<List<_i5.Video>>);

  @override
  _i3.Future<List<_i5.Video>> getNextFilteredVideos({
    required _i4.DocumentSnapshot<Object?>? lastVideo,
    required Set<String>? filterIds,
    int? limit = 10,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#getNextFilteredVideos, [], {
              #lastVideo: lastVideo,
              #filterIds: filterIds,
              #limit: limit,
            }),
            returnValue: _i3.Future<List<_i5.Video>>.value(<_i5.Video>[]),
          )
          as _i3.Future<List<_i5.Video>>);

  @override
  _i3.Future<List<_i5.Video>> searchVideos(
    String? query, {
    _i5.Video? startAfter,
    int? limit = 10,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #searchVideos,
              [query],
              {#startAfter: startAfter, #limit: limit},
            ),
            returnValue: _i3.Future<List<_i5.Video>>.value(<_i5.Video>[]),
          )
          as _i3.Future<List<_i5.Video>>);

  @override
  _i3.Future<List<Map<String, dynamic>>> searchUsers(
    String? query, {
    _i4.DocumentSnapshot<Object?>? startAfter,
    int? limit = 10,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #searchUsers,
              [query],
              {#startAfter: startAfter, #limit: limit},
            ),
            returnValue: _i3.Future<List<Map<String, dynamic>>>.value(
              <Map<String, dynamic>>[],
            ),
          )
          as _i3.Future<List<Map<String, dynamic>>>);
}

/// A class which mocks [VideoStateStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockVideoStateStorage extends _i1.Mock implements _i8.VideoStateStorage {
  MockVideoStateStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<void> saveVideoState(_i9.VideoState? state) =>
      (super.noSuchMethod(
            Invocation.method(#saveVideoState, [state]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<_i9.VideoState?> loadVideoState(String? videoId) =>
      (super.noSuchMethod(
            Invocation.method(#loadVideoState, [videoId]),
            returnValue: _i3.Future<_i9.VideoState?>.value(),
          )
          as _i3.Future<_i9.VideoState?>);

  @override
  _i3.Future<void> removeVideoState(String? videoId) =>
      (super.noSuchMethod(
            Invocation.method(#removeVideoState, [videoId]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> cleanup(Duration? threshold) =>
      (super.noSuchMethod(
            Invocation.method(#cleanup, [threshold]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<List<_i9.VideoState>> loadAllVideoStates() =>
      (super.noSuchMethod(
            Invocation.method(#loadAllVideoStates, []),
            returnValue: _i3.Future<List<_i9.VideoState>>.value(
              <_i9.VideoState>[],
            ),
          )
          as _i3.Future<List<_i9.VideoState>>);
}
