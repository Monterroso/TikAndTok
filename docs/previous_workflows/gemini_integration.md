# Integrating Gemini for Technical Video Analysis in a Firebase MVP

This document outlines an MVP strategy to integrate Google Cloud's Gemini AI model with Firebase for analyzing technical showcase videos. The goal is to provide automated technical analysis, implementation insights, and AI-powered technical discussions in comments.

## Architecture Overview

We'll leverage our existing Firebase setup and state management patterns:
- **Frontend (Flutter App):**  
  - Uses Provider + Freezed for state management
  - Maintains existing video viewing components
  - Adds new UI components for technical metadata display
- **Firebase Storage:**  
  Stores the uploaded videos
- **Cloud Functions for Firebase:**  
  Handles video processing pipeline with Gemini API
- **Firestore:**  
  - Existing `videos` collection for core video data
  - New `video_analysis` collection for technical analysis content
- **Vertex AI (Gemini):**  
  Used for technical video analysis to extract:
  - Implementation overview
  - Technical stack details
  - Architecture patterns
  - Best practices identified
  - Technical categories/tags
  - Comment-triggered technical discussions

## Data Models

### VideoAnalysis Model
Located in `lib/models/video_analysis.dart`:
```dart
@freezed
class VideoAnalysis with _$VideoAnalysis {
  const factory VideoAnalysis({
    required String videoId,
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
```

### VideoAnalysisState
Located in `lib/state/video_analysis_state.dart`:
```dart
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
}
```

## Service Layer

### GeminiService
Located in `lib/services/gemini_service.dart`:
```dart
@injectable
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
```

## Controller Layer

### VideoAnalysisController
Located in `lib/controllers/video_analysis_controller.dart`:
```dart
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
```

## UI Components

### TechnicalMetadataDisplay
Located in `lib/widgets/video_viewing/technical_metadata_display.dart`:
```dart
class TechnicalMetadataDisplay extends StatelessWidget {
  final String videoId;

  const TechnicalMetadataDisplay({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VideoAnalysisController(
        context.read<GeminiService>(),
        videoId,
      ),
      child: Consumer<VideoAnalysisController>(
        builder: (context, controller, _) {
          final state = controller.state;
          
          if (state.isLoading) {
            return const CircularProgressIndicator();
          }

          final analysis = state.analysis;
          if (analysis == null) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technical Implementation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (analysis.implementationOverview != null)
                Text(analysis.implementationOverview!),
              const SizedBox(height: 8),
              Text(
                'Tech Stack',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: analysis.techStack
                    .map((tech) => Chip(label: Text(tech)))
                    .toList(),
              ),
              if (analysis.architecturePatterns.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Architecture Patterns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: analysis.architecturePatterns
                      .map((pattern) => Chip(label: Text(pattern)))
                      .toList(),
                ),
              ],
              if (analysis.bestPractices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Best Practices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...analysis.bestPractices
                    .map((practice) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(practice),
                        ))
                    .toList(),
              ],
            ],
          );
        },
      ),
    );
  }
}
```

## Cloud Functions Implementation

Located in `functions/src/video_processing.ts`:
```typescript
import * as functions from 'firebase-functions';
import { VertexAI } from '@google-cloud/vertexai';

export const processVideoWithGemini = functions.firestore
  .document('videos/{videoId}')
  .onCreate(async (snap, context) => {
    const videoId = context.params.videoId;
    const videoData = snap.data();
    const videoUrl = videoData.url;

    try {
      // Initialize Vertex AI with Gemini
      const vertexAI = new VertexAI({
        project: process.env.GOOGLE_CLOUD_PROJECT!,
        location: 'us-central1',
      });

      const model = vertexAI.getGenerativeModel('gemini-pro-vision');

      // Process video with Gemini
      const result = await model.generateContent({
        contents: [{ video: videoUrl }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 2048,
        },
        prompt: `Analyze this technical showcase video. Focus on:
          1. The main technical implementation being demonstrated
          2. Key technologies and frameworks used
          3. Notable architectural patterns or design choices
          4. Technical challenges addressed
          5. Best practices demonstrated
          
          Categorize the video using relevant technical categories like:
          - Frontend Frameworks (React, Vue, Angular, etc.)
          - Backend Technologies (Node.js, Python, Java, etc.)
          - Database Solutions (SQL, NoSQL, etc.)
          - Architecture Patterns (Microservices, Monolith, etc.)
          - DevOps Practices (CI/CD, Container Orchestration, etc.)
          - Testing Approaches (Unit, Integration, E2E)
          
          Provide a technical summary that would be helpful for other developers 
          looking to implement similar solutions.`
      });

      // Parse Gemini response
      const analysis = {
        videoId,
        implementationOverview: result.implementationOverview,
        technicalDetails: result.technicalDetails,
        techStack: result.techStack,
        architecturePatterns: result.architecturePatterns,
        bestPractices: result.bestPractices,
        isProcessing: false,
      };

      // Update Firestore
      await admin.firestore()
        .collection('video_analysis')
        .doc(videoId)
        .set(analysis);

    } catch (error) {
      console.error('Error processing video:', error);
      await admin.firestore()
        .collection('video_analysis')
        .doc(videoId)
        .set({
          videoId,
          isProcessing: false,
          error: error.message,
        });
    }
  });

export const handleCommentTrigger = functions.firestore
  .document('videos/{videoId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const commentData = snap.data();
    const { text, userId } = commentData;
    const { videoId, commentId } = context.params;

    // Only proceed if trigger word is present
    if (!text.toLowerCase().includes('just submit')) {
      return;
    }

    try {
      // Get both video and its analysis for technical context
      const [videoDoc, analysisDoc] = await Promise.all([
        admin.firestore().collection('videos').doc(videoId).get(),
        admin.firestore().collection('video_analysis').doc(videoId).get()
      ]);

      const videoData = videoDoc.data();
      const analysisData = analysisDoc.data();

      // Initialize Gemini
      const vertexAI = new VertexAI({
        project: process.env.GOOGLE_CLOUD_PROJECT!,
        location: 'us-central1',
      });
      const model = vertexAI.getGenerativeModel('gemini-pro');

      // Technical-focused prompt
      const response = await model.generateContent({
        contents: [{
          role: 'user',
          parts: [{
            text: `Context: This is a technical showcase video about ${videoData.title}.
                   Technical Analysis: ${analysisData.technicalDetails}
                   Tech Stack: ${analysisData.techStack.join(', ')}
                   
                   User comment: ${text}
                   
                   Generate a technical response focusing on the implementation details, 
                   architecture choices, and best practices shown in the video. 
                   If the user asked about specific technical aspects, address those directly.
                   Keep the response concise but technically precise.`
          }]
        }],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 1024,
        },
      });

      // Post AI response as a comment
      await admin.firestore()
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .add({
          text: response.text,
          userId: 'gemini-ai',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          replyTo: commentId,
        });

    } catch (error) {
      console.error('Error:', error);
    }
  });
```

## Implementation Steps

1. **Model and State Setup**
   - Create VideoAnalysis and VideoAnalysisState models
   - Generate Freezed code
   - Add to dependency injection setup

2. **Service Layer**
   - Implement GeminiService
   - Add to dependency injection container
   - Set up Firestore integration

3. **Controller Implementation**
   - Create VideoAnalysisController
   - Implement state management
   - Add error handling

4. **UI Components**
   - Create TechnicalMetadataDisplay widget
   - Integrate with existing video viewing screen
   - Add loading and error states
   - Style technical metadata presentation

5. **Cloud Function**
   - Set up Vertex AI integration
   - Implement video processing pipeline
   - Add comment trigger handling
   - Deploy and test

## Testing Strategy

1. **Unit Tests**
   - Test VideoAnalysis model serialization
   - Test VideoAnalysisController state transitions
   - Test GeminiService methods

2. **Widget Tests**
   - Test TechnicalMetadataDisplay loading states
   - Test error handling display
   - Test technical metadata presentation

3. **Integration Tests**
   - Test full video processing pipeline
   - Test real-time updates
   - Test comment trigger responses

## Error Handling

1. **Processing Failures**
   - Fall back to user-provided descriptions
   - Show error state in UI
   - Allow manual refresh

2. **Network Issues**
   - Show connection error states
   - Provide fallback content

3. **Invalid Responses**
   - Validate Gemini output
   - Handle missing or malformed data

## Future Enhancements

1. **Advanced Analysis**
   - Code snippet extraction
   - Performance metrics analysis
   - Security best practices detection

2. **Technical Categories**
   - Hierarchical tech stack organization
   - Version detection
   - Framework-specific insights

3. **Performance Optimizations**
   - Response caching
   - Batch processing
   - Lazy loading of technical details

---

This integration plan focuses on technical video analysis and provides a foundation for AI-powered technical discussions within the platform.
