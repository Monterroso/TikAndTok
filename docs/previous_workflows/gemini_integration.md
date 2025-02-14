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
    required String implementationOverview,
    String? technicalDetails,
    required KeyPoints keyPoints,
    @Default(1) int version,        // For future data structure versioning
    @Default([]) List<ContentChunk> chunks,  // For future RAG implementation
    @Default(false) bool isProcessing,
    String? error,
    required DateTime lastUpdated,
  }) = _VideoAnalysis;

  factory VideoAnalysis.fromJson(Map<String, dynamic> json) => 
      _$VideoAnalysisFromJson(json);
}

@freezed
class KeyPoints with _$KeyPoints {
  const factory KeyPoints({
    @Default([]) List<String> techStack,
    @Default([]) List<String> patterns,
    @Default([]) List<String> bestPractices,
  }) = _KeyPoints;

  factory KeyPoints.fromJson(Map<String, dynamic> json) => 
      _$KeyPointsFromJson(json);
}

@freezed
class ContentChunk with _$ContentChunk {
  const factory ContentChunk({
    required String content,
    int? timestamp,
    Map<String, dynamic>? metadata,
  }) = _ContentChunk;

  factory ContentChunk.fromJson(Map<String, dynamic> json) => 
      _$ContentChunkFromJson(json);
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

## Context Management

### Current Implementation
```typescript
interface VideoAnalysis {
  implementationOverview: string;
  technicalDetails?: string;
  keyPoints: {
    techStack: string[];
    patterns: string[];
    bestPractices: string[];
  };
  version: number;        // For future data structure versioning
  chunks?: {             // Optional field for future RAG implementation
    content: string;
    timestamp?: number;
    metadata?: Record<string, any>;
  }[];
  isProcessing: boolean;
  error?: string;
  lastUpdated: Timestamp;
}
```

Our implementation focuses on simplicity while maintaining extensibility:

1. **Core Features**
   - High-level technical summary (implementationOverview)
   - Structured key points (tech stack, patterns, practices)
   - Direct integration with comment system
   - Processing state tracking
   - Error handling
   - Version control for future updates
   - Support for future RAG implementation

2. **Future-Proofing**
   - Version field for tracking schema changes
   - Chunks array for future RAG implementation
   - Extensible metadata structure
   - Timestamp support for future video segment linking

3. **Question Handling**
   - Trigger phrase detection ("just submit")
   - Context lookup from video_analysis collection
   - Structured response format with key points
   - Responses stored as regular reply comments
   - Parent-child relationship for context

4. **Response Format**
   ```
   Technical Implementation Analysis:

   Tech Stack:
   • [Technology 1]
   • [Technology 2]

   Architecture Patterns:
   • [Pattern 1]
   • [Pattern 2]

   Implementation Overview:
   [Summary of implementation]

   Best Practices:
   • [Practice 1]
   • [Practice 2]
   ```

This implementation provides:
- Clear technical insights
- Structured, readable responses
- Easy integration with existing comment system
- Foundation for future RAG enhancement
- Maintainable codebase
- Single source of truth for technical analysis

### Migration Path to RAG

When ready to enhance with RAG capabilities, we can:

1. **Enhance Content Storage**
   ```typescript
   // Future enhancement of the chunks field
   interface ContentChunk {
     content: string;
     timestamp?: number;
     embedding?: number[];    // For vector similarity search
     metadata?: {
       techStack: string[];
       context: string;
       references: string[];
     };
   }
   ```

2. **Gradual Feature Rollout**
   - Phase 1 (Current): Basic technical analysis with key points
   - Phase 2: Add content chunks without embeddings
   - Phase 3: Implement embeddings and vector search
   - Phase 4: Full RAG with advanced context handling

3. **Backward Compatibility**
   - Version field enables smooth migrations
   - Existing comments and responses remain valid
   - Progressive enhancement of search capabilities
   - Support for both simple and advanced queries

### Future RAG Implementation

The current `chunks` field in our `VideoAnalysis` interface will be enhanced to support:
- Detailed technical content
- Video timestamp linking
- Vector embeddings for similarity search
- Rich metadata and references
- Section context
- Related concepts

#### RAG Implementation Strategy

1. **Content Processing**
   - Break down technical analysis into semantic chunks
   - Generate embeddings for each chunk
   - Store chunks and embeddings in the video_analysis document
   - Maintain relationships between related technical concepts

2. **Enhanced Query Processing**
   ```typescript
   interface TechnicalQuery {
     question: string;
     context: {
       previousQuestions: string[];
       relevantTimestamps: number[];
       focusAreas: string[];     // e.g., "architecture", "implementation"
     };
     constraints: {
       maxTokens: number;
       temperature: number;
       technicalDepth: 'basic' | 'intermediate' | 'advanced';
     };
   }
   ```

3. **Retrieval Process**
   - Convert user question into embedding
   - Perform semantic search within chunks
   - Consider temporal context (video timestamps)
   - Include related technical concepts
   - Retrieve connected documentation/code references

4. **Response Generation**
   - Combine retrieved chunks with question context
   - Generate technically precise responses
   - Include references to specific timestamps
   - Link to relevant documentation/code
   - Maintain technical accuracy through fact-checking

5. **Performance Optimizations**
   - Implement chunk caching
   - Use approximate nearest neighbor search
   - Batch embedding generation
   - Progressive loading of context
   - Optimize document queries

### Technical Discussions in Comments
Technical discussions are integrated directly into the existing comment system:
- Users trigger technical discussions by prefixing comments with "just submit"
- System responses are added as regular reply comments
- No special comment structure needed - keeps the system simple and maintainable
- Technical context is retrieved from the video_analysis collection
- Parent-child relationship of comments naturally maintains discussion context

### Implementation Strategy

1. **Initial Analysis**
   - When a video is first processed, generate both the overview and key points
   - Store the analysis in the video_analysis collection
   - Index key technical terms for efficient retrieval

2. **Query Handling**
   - Detect technical questions through the "just submit" prefix
   - Look up relevant analysis from video_analysis
   - Generate response using the analysis data
   - Store response as a regular reply comment
   - Use standard comment parent-child relationship for thread context

3. **Performance Considerations**
   - Cache frequently accessed analyses
   - Use efficient indexing for lookups
   - Implement rate limiting for API calls
   - Keep technical context concise and focused

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

### TechnicalMetadataDisplay ✓
Located in `lib/widgets/video_viewing/technical_metadata_display.dart`:
- Implementation complete and exceeds original requirements
- Features implemented:
  - Implementation overview section
  - Tech stack chips with visual styling
  - Architecture patterns display
  - Best practices list with checkmark icons
  - Loading states with proper UI feedback
  - Error handling with retry functionality
  - Theme integration
  - Responsive layout
  - Proper null safety handling
  - Integrated with state management
  - Used in RightActionsColumn for technical details display

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
    const db = getFirestore();

    try {
      // Initialize processing state
      await db.collection('video_analysis').doc(videoId).set({
        isProcessing: true,
        techStack: [],
        architecturePatterns: [],
        bestPractices: [],
      });

      // TODO: Initialize Vertex AI with Gemini
      // const vertexAI = new VertexAI({...});
      // const model = vertexAI.getGenerativeModel('gemini-pro-vision');

      // Generate analysis (mock data for now)
      const analysis: VideoAnalysis = {
        implementationOverview: "Technical implementation analysis pending Gemini integration",
        technicalDetails: "Detailed analysis will be available once Gemini processing is implemented",
        techStack: ["Flutter", "Firebase"],
        architecturePatterns: ["MVVM", "Clean Architecture"],
        bestPractices: ["State Management", "Error Handling"],
        isProcessing: false,
      };

      // Generate and store technical context
      const technicalContext: VideoAnalysis = {
        implementationOverview: analysis.implementationOverview || '',
        technicalDetails: analysis.technicalDetails,
        keyPoints: {
          techStack: analysis.techStack,
          patterns: analysis.architecturePatterns,
          bestPractices: analysis.bestPractices,
        },
        version: 1,
        chunks: [],
        isProcessing: false,
        lastUpdated: admin.firestore.Timestamp.now(),
      };

      // Store both analysis and context
      await Promise.all([
        db.collection('video_analysis').doc(videoId).set(analysis),
        db.collection('video_analysis').doc(videoId).set(technicalContext),
      ]);

    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      
      // Update both analysis and context with error state
      await Promise.all([
        db.collection('video_analysis').doc(videoId).set({
          isProcessing: false,
          error: errorMessage,
          techStack: [],
          architecturePatterns: [],
          bestPractices: [],
        }),
        db.collection('video_analysis').doc(videoId).set({
          implementationOverview: 'Error during technical analysis',
          technicalDetails: errorMessage,
          keyPoints: {
            techStack: [],
            patterns: [],
            bestPractices: [],
          },
          version: 1,
          chunks: [],
          isProcessing: false,
          lastUpdated: admin.firestore.Timestamp.now(),
        }),
      ]);
    }
  });

export const handleTechnicalDiscussion = functions.firestore
  .document('videos/{videoId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const { videoId, commentId } = context.params;
    const commentData = snap.data();
    const { text } = commentData;

    // Only proceed if it's a technical question
    if (!text.toLowerCase().includes('just submit')) {
      return;
    }

    try {
      // Get technical context
      const contextDoc = await db.collection('video_analysis').doc(videoId).get();
      const technicalContext = contextDoc.data() as VideoAnalysis;

      // Extract the actual question
      const question = text.replace(/just submit/i, '').trim();

      // TODO: Initialize Vertex AI with Gemini
      // const vertexAI = new VertexAI({...});
      // const model = vertexAI.getGenerativeModel('gemini-pro');

      // Add response as a regular reply comment
      await db.collection('videos').doc(videoId)
        .collection('comments').add({
          text: generateResponse(question, technicalContext),
          userId: 'system',
          parentId: commentId,
          createdAt: admin.firestore.Timestamp.now(),
        });

    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      
      // Add error response as a comment
      await db.collection('videos').doc(videoId)
        .collection('comments').add({
          text: `Sorry, I couldn't process your technical question: ${errorMessage}`,
          userId: 'system',
          parentId: commentId,
          createdAt: admin.firestore.Timestamp.now(),
        });
    }
  });
```

## Implementation Steps

1. **Model and State Setup** ✓
   - Create VideoAnalysis and VideoAnalysisState models
   - Generate Freezed code
   - Add to dependency injection setup

2. **Service Layer** ✓
   - Implement GeminiService
   - Add to dependency injection container
   - Set up Firestore integration

3. **Controller Implementation** ✓
   - Create VideoAnalysisController
   - Implement state management
   - Add error handling

4. **UI Components** ✓
   - TechnicalMetadataDisplay widget complete and exceeds requirements
   - Integrated with video viewing screen
   - Loading and error states implemented
   - Technical metadata presentation styled and polished

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
