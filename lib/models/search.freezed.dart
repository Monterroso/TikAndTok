// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SearchState _$SearchStateFromJson(Map<String, dynamic> json) {
  return _SearchState.fromJson(json);
}

/// @nodoc
mixin _$SearchState {
  String get query => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  List<Video> get videoResults => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get userResults =>
      throw _privateConstructorUsedError;
  List<String> get recentSearches => throw _privateConstructorUsedError;

  /// Serializes this SearchState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchStateCopyWith<SearchState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchStateCopyWith<$Res> {
  factory $SearchStateCopyWith(
          SearchState value, $Res Function(SearchState) then) =
      _$SearchStateCopyWithImpl<$Res, SearchState>;
  @useResult
  $Res call(
      {String query,
      bool isLoading,
      String? error,
      List<Video> videoResults,
      List<Map<String, dynamic>> userResults,
      List<String> recentSearches});
}

/// @nodoc
class _$SearchStateCopyWithImpl<$Res, $Val extends SearchState>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? videoResults = null,
    Object? userResults = null,
    Object? recentSearches = null,
  }) {
    return _then(_value.copyWith(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      videoResults: null == videoResults
          ? _value.videoResults
          : videoResults // ignore: cast_nullable_to_non_nullable
              as List<Video>,
      userResults: null == userResults
          ? _value.userResults
          : userResults // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      recentSearches: null == recentSearches
          ? _value.recentSearches
          : recentSearches // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchStateImplCopyWith<$Res>
    implements $SearchStateCopyWith<$Res> {
  factory _$$SearchStateImplCopyWith(
          _$SearchStateImpl value, $Res Function(_$SearchStateImpl) then) =
      __$$SearchStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String query,
      bool isLoading,
      String? error,
      List<Video> videoResults,
      List<Map<String, dynamic>> userResults,
      List<String> recentSearches});
}

/// @nodoc
class __$$SearchStateImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchStateImpl>
    implements _$$SearchStateImplCopyWith<$Res> {
  __$$SearchStateImplCopyWithImpl(
      _$SearchStateImpl _value, $Res Function(_$SearchStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? videoResults = null,
    Object? userResults = null,
    Object? recentSearches = null,
  }) {
    return _then(_$SearchStateImpl(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      videoResults: null == videoResults
          ? _value._videoResults
          : videoResults // ignore: cast_nullable_to_non_nullable
              as List<Video>,
      userResults: null == userResults
          ? _value._userResults
          : userResults // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      recentSearches: null == recentSearches
          ? _value._recentSearches
          : recentSearches // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchStateImpl with DiagnosticableTreeMixin implements _SearchState {
  const _$SearchStateImpl(
      {required this.query,
      this.isLoading = false,
      this.error,
      final List<Video> videoResults = const [],
      final List<Map<String, dynamic>> userResults = const [],
      final List<String> recentSearches = const []})
      : _videoResults = videoResults,
        _userResults = userResults,
        _recentSearches = recentSearches;

  factory _$SearchStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchStateImplFromJson(json);

  @override
  final String query;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  final List<Video> _videoResults;
  @override
  @JsonKey()
  List<Video> get videoResults {
    if (_videoResults is EqualUnmodifiableListView) return _videoResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_videoResults);
  }

  final List<Map<String, dynamic>> _userResults;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get userResults {
    if (_userResults is EqualUnmodifiableListView) return _userResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userResults);
  }

  final List<String> _recentSearches;
  @override
  @JsonKey()
  List<String> get recentSearches {
    if (_recentSearches is EqualUnmodifiableListView) return _recentSearches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentSearches);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SearchState(query: $query, isLoading: $isLoading, error: $error, videoResults: $videoResults, userResults: $userResults, recentSearches: $recentSearches)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SearchState'))
      ..add(DiagnosticsProperty('query', query))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('videoResults', videoResults))
      ..add(DiagnosticsProperty('userResults', userResults))
      ..add(DiagnosticsProperty('recentSearches', recentSearches));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchStateImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            const DeepCollectionEquality()
                .equals(other._videoResults, _videoResults) &&
            const DeepCollectionEquality()
                .equals(other._userResults, _userResults) &&
            const DeepCollectionEquality()
                .equals(other._recentSearches, _recentSearches));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      query,
      isLoading,
      error,
      const DeepCollectionEquality().hash(_videoResults),
      const DeepCollectionEquality().hash(_userResults),
      const DeepCollectionEquality().hash(_recentSearches));

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchStateImplCopyWith<_$SearchStateImpl> get copyWith =>
      __$$SearchStateImplCopyWithImpl<_$SearchStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchStateImplToJson(
      this,
    );
  }
}

abstract class _SearchState implements SearchState {
  const factory _SearchState(
      {required final String query,
      final bool isLoading,
      final String? error,
      final List<Video> videoResults,
      final List<Map<String, dynamic>> userResults,
      final List<String> recentSearches}) = _$SearchStateImpl;

  factory _SearchState.fromJson(Map<String, dynamic> json) =
      _$SearchStateImpl.fromJson;

  @override
  String get query;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  List<Video> get videoResults;
  @override
  List<Map<String, dynamic>> get userResults;
  @override
  List<String> get recentSearches;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchStateImplCopyWith<_$SearchStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
