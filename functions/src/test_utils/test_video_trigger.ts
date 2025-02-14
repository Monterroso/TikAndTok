import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import * as admin from 'firebase-admin';
import { VideoDocument } from '../video_processing';

interface TestConfig {
  useEmulator: boolean;
  projectId: string;
  waitTime: number; // milliseconds to wait for function execution
}

const defaultConfig: TestConfig = {
  useEmulator: true,
  projectId: 'tikandtok-684cb',
  waitTime: 5000
};

function initializeFirebase(config: TestConfig) {
  // Set emulator environment variables if using emulator
  if (config.useEmulator) {
    process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
    process.env.FUNCTIONS_EMULATOR_HOST = 'localhost:5001';
    console.log('Using emulator environment:', {
      FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
      FUNCTIONS_EMULATOR_HOST: process.env.FUNCTIONS_EMULATOR_HOST
    });
  } else {
    // Clear emulator variables if they were set
    delete process.env.FIRESTORE_EMULATOR_HOST;
    delete process.env.FUNCTIONS_EMULATOR_HOST;
    console.log('Using production environment');
    
    // For production, use service account
    const serviceAccount = require('../../.env/serviceAccountKey.json');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      return getFirestore();
    }
  }

  // Initialize Firebase Admin for emulator
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  return getFirestore();
}

async function createTestVideo(config: TestConfig = defaultConfig) {
  const db = initializeFirebase(config);
  
  try {
    console.log('Creating test video document...');
    
    const testVideo: Partial<VideoDocument> = {
      url: 'https://firebasestorage.googleapis.com/v0/b/tikandtok-684cb.firebasestorage.app/o/videos%2F(27)%20Inbox%20%EF%BD%9C%20marcus.monterroso%40gauntletai.com%20%EF%BD%9C%20Proton%20Mail%20-%205%20February%202025%20%5B00ca5037fd9d410ab38d11803a4d2d33%5D.mp4?alt=media&token=8b314bbd-1340-46b0-9278-fcf32392b55f',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      title: 'Flutter Clean Architecture Implementation',
      platform: 'youtube' as const,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      likedBy: [],
      savedBy: [],
      comments: 0,
      userId: 'sYkDKhNOQXdDNYPJ0krj',
      description: 'A technical showcase of Flutter clean architecture implementation'
    };

    console.log('Test video object prepared:', testVideo);
    const docRef = await db.collection('videos').add(testVideo);
    console.log(`Test video created with ID: ${docRef.id}`);
    
    // Wait for function execution
    console.log(`Waiting ${config.waitTime}ms for function trigger...`);
    await new Promise(resolve => setTimeout(resolve, config.waitTime));

    // Check if the analysis document was created
    console.log('Checking for video analysis document...');
    const analysisDoc = await db.collection('video_analysis').doc(docRef.id).get();
    if (analysisDoc.exists) {
      console.log('Analysis document exists:', analysisDoc.data());
    } else {
      console.log('No analysis document found');
    }

    return {
      videoId: docRef.id,
      analysisExists: analysisDoc.exists,
      analysisData: analysisDoc.data()
    };

  } catch (error) {
    console.error('Error in test:', error);
    throw error;
  }
}

// Allow running from command line with environment argument
if (require.main === module) {
  const args = process.argv.slice(2);
  const useEmulator = args[0] !== 'prod';
  
  console.log(`Starting test execution in ${useEmulator ? 'emulator' : 'production'} mode...`);
  createTestVideo({ ...defaultConfig, useEmulator })
    .then(result => {
      console.log('Test completed:', result);
      process.exit(0);
    })
    .catch(error => {
      console.error('Test failed:', error);
      process.exit(1);
    });
} 