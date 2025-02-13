import * as admin from 'firebase-admin';

// Initialize Firebase Admin (it will automatically use emulator if started)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'tikandtok-684cb'
  });
}

// Connect to the Firestore emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

const db = admin.firestore();

async function createTestTweet() {
  try {
    const tweetRef = await db.collection('tweets').add({
      originalAuthor: {
        displayName: "@jlory__",
        username: "Israel Lory",
        profileId: "GauntletAIDemos"
      },
      repostedBy: {
        displayName: "GauntletAI Demo Feed",
        username: "GauntletAI Demo Feed",
        scrapeSessionId: "fd819075-4c89-4f14-bbe3-1428aefe6048"
      },
      scrapedAt: admin.firestore.Timestamp.fromDate(new Date("2025-02-12T18:27:13Z")),
      text: "Talking shop on Jocus, my in-progress meme video creation/sharing app for /joingauntletai Week 5 https://t.co/4SvRUoJjJw /hashtag/GauntletAI?src=hashtag_click",
      timestamp: admin.firestore.Timestamp.fromDate(new Date("2025-02-06T00:33:36Z")),
      url: "https://x.com/Israel Lory/status/undefined",
      urls: [
        "/joingauntletai",
        "https://t.co/4SvRUoJjJw",
        "/hashtag/GauntletAI?src=hashtag_click"
      ],
      isProcessed: false
    });

    console.log(`Created test tweet with ID: ${tweetRef.id}`);
  } catch (error) {
    console.error('Error creating test tweet:', error);
  }
}

// Execute if this file is run directly
if (require.main === module) {
  createTestTweet()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

export { createTestTweet }; 