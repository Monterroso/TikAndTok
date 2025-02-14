// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_analysis_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VideoAnalysisState _$VideoAnalysisStateFromJson(Map<String, dynamic> json) {
  return _VideoAnalysisState.fromJson(json);
}

/// @nodoc
mixin _$VideoAnalysisState {
  String get videoId => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  VideoAnalysis? get analysis => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this VideoAnalysisState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoAnalysisState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoAnalysisStateCopyWith<VideoAnalysisState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoAnalysisStateCopyWith<$Res> {
  factory $VideoAnalysisStateCopyWith(
          VideoAnalysisState value, $Res Function(VideoAnalysisState) then) =
      _$VideoAnalysisStateCopyWithImpl<$Res, VideoAnalysisState>;
  @useResult
  $Res call(
      {String videoId, bool isLoading, VideoAnalysis? analysis, String? error});

  $VideoAnalysisCopyWith<$Res>? get analysis;
}

/// @nodoc
class _$VideoAnalysisStateCopyWithImpl<$Res, $Val extends VideoAnalysisState>
    implements $VideoAnalysisStateCopyWith<$Res> {
  _$VideoAnalysisStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoAnalysisState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? isLoading = null,
    Object? analysis = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      analysis: freezed == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as VideoAnalysis?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of VideoAnalysisState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoAnalysisCopyWith<$Res>? get analysis {
    if (_value.analysis == null) {
      return null;
    }

    return $VideoAnalysisCopyWith<$Res>(_value.analysis!, (value) {
      return _then(_value.copyWith(analysis: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VideoAnalysisStateImplCopyWith<$Res>
    implements $VideoAnalysisStateCopyWith<$Res> {
  factory _$$VideoAnalysisStateImplCopyWith(_$VideoAnalysisStateImpl value,
          $Res Function(_$VideoAnalysisStateImpl) then) =
      __$$VideoAnalysisStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String videoId, bool isLoading, VideoAnalysis? analysis, String? error});

  @override
  $VideoAnalysisCopyWith<$Res>? get analysis;
}

/// @nodoc
class __$$VideoAnalysisStateImplCopyWithImpl<$Res>
    extends _$VideoAnalysisStateCopyWithImpl<$Res, _$VideoAnalysisStateImpl>
    implements _$$VideoAnalysisStateImplCopyWith<$Res> {
  __$$VideoAnalysisStateImplCopyWithImpl(_$VideoAnalysisStateImpl _value,
      $Res Function(_$VideoAnalysisStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoAnalysisState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? isLoading = null,
    Object? analysis = freezed,
    Object? error = freezed,
  }) {
    return _then(_$VideoAnalysisStateImpl(
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      analysis: freezed == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as VideoAnalysis?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoAnalysisStateImpl implements _VideoAnalysisState {
  const _$VideoAnalysisStateImpl(
      {required this.videoId,
      this.isLoading = false,
      this.analysis,
      this.error});

  factory _$VideoAnalysisStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoAnalysisStateImplFromJson(json);

  @override
  final String videoId;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final VideoAnalysis? analysis;
  @override
  final String? error;

  @override
  String toString() {
    return 'VideoAnalysisState(videoId: $videoId, isLoading: $isLoading, analysis: $analysis, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoAnalysisStateImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.analysis, analysis) ||
                other.analysis == analysis) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, videoId, isLoading, analysis, error);

  /// Create a copy of VideoAnalysisState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoAnalysisStateImplCopyWith<_$VideoAnalysisStateImpl> get copyWith =>
      __$$VideoAnalysisStateImplCopyWithImpl<_$VideoAnalysisStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoAnalysisStateImplToJson(
      this,
    );
  }
}

abstract class _VideoAnalysisState implements VideoAnalysisState {
  const factory _VideoAnalysisState(
      {required final String videoId,
      final bool isLoading,
      final VideoAnalysis? analysis,
      final String? error}) = _$VideoAnalysisStateImpl;

  factory _VideoAnalysisState.fromJson(Map<String, dynamic> json) =
      _$VideoAnalysisStateImpl.fromJson;

  @override
  String get videoId;
  @override
  bool get isLoading;
  @override
  VideoAnalysis? get analysis;
  @override
  String? get error;

  /// Create a copy of VideoAnalysisState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoAnalysisStateImplCopyWith<_$VideoAnalysisStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
