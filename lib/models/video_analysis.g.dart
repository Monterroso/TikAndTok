// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoAnalysisImpl _$$VideoAnalysisImplFromJson(Map<String, dynamic> json) =>
    _$VideoAnalysisImpl(
      implementationOverview: json['implementationOverview'] as String?,
      technicalDetails: json['technicalDetails'] as String?,
      techStack: (json['techStack'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      architecturePatterns: (json['architecturePatterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      bestPractices: (json['bestPractices'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isProcessing: json['isProcessing'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$VideoAnalysisImplToJson(_$VideoAnalysisImpl instance) =>
    <String, dynamic>{
      'implementationOverview': instance.implementationOverview,
      'technicalDetails': instance.technicalDetails,
      'techStack': instance.techStack,
      'architecturePatterns': instance.architecturePatterns,
      'bestPractices': instance.bestPractices,
      'isProcessing': instance.isProcessing,
      'error': instance.error,
    };
