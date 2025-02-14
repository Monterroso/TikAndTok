import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import * as admin from 'firebase-admin';
import { VideoDocument } from '../video_processing';

// Initialize Firebase Admin (for local testing)
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FUNCTIONS_EMULATOR_HOST = 'localhost:5001';

console.log('Starting test with environment:', {
  FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
  FUNCTIONS_EMULATOR_HOST: process.env.FUNCTIONS_EMULATOR_HOST
});

admin.initializeApp({
  projectId: 'tikandtok-684cb'
});

const db = getFirestore();

async function createTestVideo() {
  try {
    console.log('Creating test video document...');
    
    const testVideo: Partial<VideoDocument> = {
      url: 'https://example.com/test-video',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      title: 'Flutter Clean Architecture Implementation',
      platform: 'youtube' as const,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      likedBy: [],
      savedBy: [],
      comments: 0,
      userId: 'test-user-123',
      description: 'A technical showcase of Flutter clean architecture implementation'
    };

    console.log('Test video object prepared:', testVideo);
    const docRef = await db.collection('videos').add(testVideo);
    console.log(`Test video created with ID: ${docRef.id}`);
    
    // Wait longer to see the function logs
    console.log('Waiting for function trigger...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Check if the analysis document was created
    console.log('Checking for video analysis document...');
    const analysisDoc = await db.collection('video_analysis').doc(docRef.id).get();
    if (analysisDoc.exists) {
      console.log('Analysis document exists:', analysisDoc.data());
    } else {
      console.log('No analysis document found');
    }

  } catch (error) {
    console.error('Error in test:', error);
  } finally {
    // Exit after completion
    process.exit(0);
  }
}

// Run the test
console.log('Starting test execution...');
createTestVideo(); 