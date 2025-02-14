import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';
import '../state/video_analysis_state.dart';
import '../models/video_analysis.dart';

class VideoAnalysisController extends ChangeNotifier {
  final GeminiService _geminiService;
  VideoAnalysisState _state;
  StreamSubscription<VideoAnalysis>? _subscription;

  VideoAnalysisController(this._geminiService, String videoId)
      : _state = VideoAnalysisState.initial(videoId) {
    _initialize();
  }

  VideoAnalysisState get state => _state;

  void _initialize() {
    _subscription = _geminiService
        .streamVideoAnalysis(_state.videoId)
        .listen(
          _handleAnalysisUpdate,
          onError: _handleError,
        );
  }

  void _handleAnalysisUpdate(VideoAnalysis analysis) {
    _state = _state.copyWith(
      isLoading: false,
      analysis: analysis,
    );
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _state = _state.copyWith(
      isLoading: false,
      error: error.toString(),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
} 