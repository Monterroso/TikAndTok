import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_analysis.freezed.dart';
part 'video_analysis.g.dart';

@freezed
class VideoAnalysis with _$VideoAnalysis {
  const factory VideoAnalysis({
    String? implementationOverview,
    String? technicalDetails,
    @Default([]) List<String> techStack,
    @Default([]) List<String> architecturePatterns,
    @Default([]) List<String> bestPractices,
    @Default(false) bool isProcessing,
    String? error,
  }) = _VideoAnalysis;

  factory VideoAnalysis.fromJson(Map<String, dynamic> json) => 
      _$VideoAnalysisFromJson(json);
} 