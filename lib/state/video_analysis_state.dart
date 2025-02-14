import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/video_analysis.dart';

part 'video_analysis_state.freezed.dart';
part 'video_analysis_state.g.dart';

@freezed
class VideoAnalysisState with _$VideoAnalysisState {
  const factory VideoAnalysisState({
    required String videoId,
    @Default(false) bool isLoading,
    VideoAnalysis? analysis,
    String? error,
  }) = _VideoAnalysisState;

  factory VideoAnalysisState.initial(String videoId) => 
      VideoAnalysisState(videoId: videoId);

  factory VideoAnalysisState.fromJson(Map<String, dynamic> json) => 
      _$VideoAnalysisStateFromJson(json);
} 