import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import * as admin from 'firebase-admin';
import { VideoDocument } from '../video_processing';

// Initialize Firebase Admin (for local testing)
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FUNCTIONS_EMULATOR_HOST = 'localhost:5001';

admin.initializeApp({
  projectId: 'tikandtok-684cb'
});

const db = getFirestore();

async function createTestVideo() {
  try {
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

    console.log('Creating test video document...');
    const docRef = await db.collection('videos').add(testVideo);
    console.log(`Test video created with ID: ${docRef.id}`);
    
    // Wait a bit to see the function logs
    await new Promise(resolve => setTimeout(resolve, 2000));

  } catch (error) {
    console.error('Error creating test video:', error);
  } finally {
    // Exit after completion
    process.exit(0);
  }
}

// Run the test
createTestVideo(); 