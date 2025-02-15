import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import * as admin from 'firebase-admin';
import { VideoDocument } from '../video_processing';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

interface TestConfig {
  useEmulator: boolean;
  projectId: string;
  emulatorHosts?: {
    firestore?: string;
    storage?: string;
    auth?: string;
    functions?: string;
  };
}

const defaultConfig: TestConfig = {
  useEmulator: true,
  projectId: 'tikandtok-684cb',
  emulatorHosts: {
    firestore: 'localhost:8080',
    storage: 'localhost:9199',
    auth: 'localhost:9099',
    functions: 'localhost:5001'
  }
};

function initializeFirebase(config: TestConfig) {
  if (config.useEmulator) {
    // Set emulator hosts explicitly for testing
    process.env.FIRESTORE_EMULATOR_HOST = config.emulatorHosts?.firestore || defaultConfig.emulatorHosts?.firestore;
    process.env.FIREBASE_STORAGE_EMULATOR_HOST = config.emulatorHosts?.storage || defaultConfig.emulatorHosts?.storage;
    process.env.FIREBASE_AUTH_EMULATOR_HOST = config.emulatorHosts?.auth || defaultConfig.emulatorHosts?.auth;
    process.env.FUNCTIONS_EMULATOR_HOST = config.emulatorHosts?.functions || defaultConfig.emulatorHosts?.functions;

    console.log('Using emulator environment:', {
      FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
      FIREBASE_STORAGE_EMULATOR_HOST: process.env.FIREBASE_STORAGE_EMULATOR_HOST,
      FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
      FUNCTIONS_EMULATOR_HOST: process.env.FUNCTIONS_EMULATOR_HOST
    });
  } else {
    // Clear emulator variables if they were set
    delete process.env.FIRESTORE_EMULATOR_HOST;
    delete process.env.FIREBASE_STORAGE_EMULATOR_HOST;
    delete process.env.FIREBASE_AUTH_EMULATOR_HOST;
    delete process.env.FUNCTIONS_EMULATOR_HOST;
    console.log('Using production environment');
  }

  // Initialize Firebase Admin if not already initialized
  if (!admin.apps.length) {
    try {
      admin.initializeApp({
        projectId: config.projectId,
        credential: admin.credential.applicationDefault()
      });
      console.log('Firebase Admin initialized successfully');
    } catch (error) {
      console.error('Error initializing Firebase Admin:', error);
      throw error;
    }
  }

  return getFirestore();
}

async function waitForAnalysisCompletion(db: admin.firestore.Firestore, videoId: string, maxWaitMs = 60000): Promise<admin.firestore.DocumentSnapshot | null> {
  const startTime = Date.now();
  
  while (Date.now() - startTime < maxWaitMs) {
    const analysisDoc = await db.collection('video_analysis').doc(videoId).get();
    
    if (analysisDoc.exists) {
      const data = analysisDoc.data();
      if (data && data.isProcessing === false) {
        // Analysis is complete (either successfully or with error)
        return analysisDoc;
      }
      console.log('Analysis still processing...');
    } else {
      console.log('Waiting for analysis document to be created...');
    }
    
    // Wait a bit before checking again
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  throw new Error(`Analysis did not complete within ${maxWaitMs}ms`);
}

async function createTestVideo(config: TestConfig = defaultConfig) {
  const db = initializeFirebase(config);
  
  try {
    console.log('Creating test video document...');
    
    const testVideo: Partial<VideoDocument> = {
      url: 'https://firebasestorage.googleapis.com/v0/b/tikandtok-684cb.firebasestorage.app/o/videos%2F(27)%20Inbox%20%EF%BD%9C%20marcus.monterroso%40gauntletai.com%20%EF%BD%9C%20Proton%20Mail%20-%205%20February%202025%20%5B00ca5037fd9d410ab38d11803a4d2d33%5D.mp4?alt=media&token=8b314bbd-1340-46b0-9278-fcf32392b55f',
      thumbnailUrl: 'https://firebasestorage.googleapis.com/v0/b/tikandtok-684cb.firebasestorage.app/o/thumbnails%2Ftest_video_thumbnail.png?alt=media&token=8865b4f0-593c-4b20-9d5d-52ee231dd75a',
      title: 'Flutter Clean Architecture Implementation',
      description: 'A technical showcase of Flutter clean architecture implementation',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      likedBy: [],
      savedBy: [],
      likes: 0,
      comments: 0,
      userId: 'sYkDKhNOQXdDNYPJ0krj'
    };

    console.log('Test video object prepared:', testVideo);
    
    // Ensure we're connected to the right Firestore instance
    const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || 'production';
    console.log(`Using Firestore host: ${firestoreHost}`);
    
    // Create the video document
    console.log('Creating video document...');
    const docRef = await db.collection('videos').add(testVideo);
    console.log(`Test video created with ID: ${docRef.id}`);

    // Create the comments subcollection
    const commentsRef = docRef.collection('comments');
    // We don't need to add any comments, but this ensures the collection exists
    console.log('Comments collection path:', commentsRef.path);

    // Verify the document and its structure
    const videoDoc = await docRef.get();
    console.log('Video document exists:', videoDoc.exists);
    if (videoDoc.exists) {
      console.log('Video data:', videoDoc.data());
      
      // List collections to verify structure
      const collections = await docRef.listCollections();
      console.log('Document collections:', collections.map(col => col.id));
    }
    
    // Wait for the complete analysis
    console.log('Waiting for analysis to complete...');
    const analysisDoc = await waitForAnalysisCompletion(db, docRef.id);
    
    // Verify analysis document exists
    const verifyAnalysis = await db.collection('video_analysis').doc(docRef.id).get();
    console.log('Analysis document exists:', verifyAnalysis.exists);
    if (verifyAnalysis.exists) {
      console.log('Analysis data:', verifyAnalysis.data());
    } else {
      // Check if it might be in a different collection
      console.log('Checking other possible collections...');
      const collections = ['video_analysis', 'videoAnalysis', 'analysis'];
      for (const collection of collections) {
        const doc = await db.collection(collection).doc(docRef.id).get();
        if (doc.exists) {
          console.log(`Found document in ${collection}:`, doc.data());
        }
      }
    }

    return {
      videoId: docRef.id,
      analysisExists: analysisDoc?.exists ?? false,
      analysisData: analysisDoc?.data() ?? null
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