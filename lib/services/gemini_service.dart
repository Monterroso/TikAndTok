import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_analysis.dart';

class GeminiService {
  final FirebaseFirestore _firestore;
  
  GeminiService(this._firestore);

  Stream<VideoAnalysis> streamVideoAnalysis(String videoId) {
    return _firestore
        .collection('video_analysis')
        .doc(videoId)
        .snapshots()
        .map((doc) => VideoAnalysis.fromJson(doc.data()!));
  }

  Future<void> processVideo(String videoId, String videoUrl) async {
    try {
      await _firestore.collection('video_analysis').doc(videoId).set(
        VideoAnalysis(
          videoId: videoId,
          isProcessing: true,
        ).toJson()
      );

      // Cloud Function will handle the actual processing
    } catch (e) {
      await _firestore.collection('video_analysis').doc(videoId).set(
        VideoAnalysis(
          videoId: videoId,
          isProcessing: false,
          error: e.toString(),
        ).toJson()
      );
    }
  }
} 