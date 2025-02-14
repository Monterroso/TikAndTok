// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_analysis_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoAnalysisStateImpl _$$VideoAnalysisStateImplFromJson(
        Map<String, dynamic> json) =>
    _$VideoAnalysisStateImpl(
      videoId: json['videoId'] as String,
      isLoading: json['isLoading'] as bool? ?? false,
      analysis: json['analysis'] == null
          ? null
          : VideoAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$VideoAnalysisStateImplToJson(
        _$VideoAnalysisStateImpl instance) =>
    <String, dynamic>{
      'videoId': instance.videoId,
      'isLoading': instance.isLoading,
      'analysis': instance.analysis,
      'error': instance.error,
    };
