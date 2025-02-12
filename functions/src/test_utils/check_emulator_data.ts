import * as admin from 'firebase-admin';

// Initialize Firebase Admin with emulator
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'tikandtok-684cb'
  });
}

// Connect to the Firestore emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

const db = admin.firestore();

async function checkEmulatorData() {
  try {
    console.log('Checking Firestore Emulator data...\n');

    // Check tweets collection
    console.log('TWEETS:');
    const tweetsSnapshot = await db.collection('tweets').get();
    if (tweetsSnapshot.empty) {
      console.log('No tweets found');
    } else {
      tweetsSnapshot.forEach(doc => {
        console.log(`\nTweet ID: ${doc.id}`);
        console.log('Data:', JSON.stringify(doc.data(), null, 2));
      });
    }

    // Check videos collection
    console.log('\nVIDEOS:');
    const videosSnapshot = await db.collection('videos').get();
    if (videosSnapshot.empty) {
      console.log('No videos found');
    } else {
      videosSnapshot.forEach(doc => {
        console.log(`\nVideo ID: ${doc.id}`);
        console.log('Data:', JSON.stringify(doc.data(), null, 2));
      });
    }
  } catch (error) {
    console.error('Error checking emulator data:', error);
  }
}

// Execute if this file is run directly
if (require.main === module) {
  checkEmulatorData()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

export { checkEmulatorData }; 