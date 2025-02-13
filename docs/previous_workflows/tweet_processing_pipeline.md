# Tweet Processing Pipeline (MVP)

This document outlines the process for handling tweet documents stored in the Firebase `tweets` collection, focusing on video content using oEmbed for metadata extraction.

## Overview

- **Trigger:** The Cloud Function is triggered on new document creation in the `tweets` collection.
- **Video Processing:** 
  - Use oEmbed to extract video metadata and embed information
  - Create video document in Firestore with necessary information
- **Multiple Video Links:** 
  - Process each video link in a tweet and create separate video documents
- **Marking Processed Tweets:** 
  - Update the tweet document with a flag (`isProcessed: true`) to prevent reprocessing

## Core Interfaces

```typescript
// Define the structure for video metadata
interface VideoMetadata {
  url: string;
  thumbnailUrl: string;
  title: string;
  platform: 'youtube' | 'loom';
  embedHtml: string;  // For direct embedding
  description?: string;
}

// Define the structure for video document
interface VideoDocument extends VideoMetadata {
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  likedBy: string[];
  savedBy: string[];
  comments: number;
  tweetId: string;
  userId: string;
}
```

## Implementation

### Cloud Function

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';

admin.initializeApp();
const db = admin.firestore();

/**
 * Extract video URL from Twitter oEmbed HTML
 */
function extractVideoUrl(html: string): string | null {
  // Extract URL from Twitter's oEmbed HTML
  const urlMatch = html.match(/href="([^"]+)"/);
  return urlMatch ? urlMatch[1] : null;
}

/**
 * Get video metadata using oEmbed
 */
async function getVideoMetadata(url: string): Promise<VideoMetadata | null> {
  try {
    // First, get the resolved URL from Twitter's oEmbed
    const twitterOembed = await fetch(
      `https://publish.twitter.com/oembed?url=${encodeURIComponent(url)}`
    );
    const twitterData = await twitterOembed.json();
    
    // Extract the actual video URL from Twitter's response
    const resolvedUrl = extractVideoUrl(twitterData.html);
    if (!resolvedUrl) return null;
    
    const lowerUrl = resolvedUrl.toLowerCase();
    
    // Handle YouTube videos
    if (lowerUrl.includes('youtube.com') || lowerUrl.includes('youtu.be')) {
      const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(resolvedUrl)}&format=json`;
      const data = await fetch(oembedUrl).then(r => r.json());
      
      return {
        url: resolvedUrl,
        thumbnailUrl: data.thumbnail_url,
        title: data.title,
        platform: 'youtube',
        embedHtml: data.html,
        description: data.description
      };
    }
    
    // Handle Loom videos
    if (lowerUrl.includes('loom.com')) {
      const oembedUrl = `https://www.loom.com/v1/oembed?url=${encodeURIComponent(resolvedUrl)}`;
      const data = await fetch(oembedUrl).then(r => r.json());
      
      return {
        url: resolvedUrl,
        thumbnailUrl: data.thumbnail_url,
        title: data.title,
        platform: 'loom',
        embedHtml: data.html,
        description: data.description
      };
    }
    
    return null;
  } catch (error) {
    console.error('Error fetching video metadata:', error);
    return null;
  }
}

/**
 * Main function triggered on tweet creation
 */
export const onTweetCreated = functions.firestore
  .document('tweets/{tweetId}')
  .onCreate(async (snap, context) => {
    const tweet = snap.data();
    const urls = tweet.urls || [];
    const batch = db.batch();
    
    try {
      // Process each URL in the tweet
      for (const url of urls) {
        const metadata = await getVideoMetadata(url);
        
        if (metadata) {
          // Create video document
          const videoDoc: VideoDocument = {
            ...metadata,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            likedBy: [],
            savedBy: [],
            comments: 0,
            tweetId: context.params.tweetId,
            userId: tweet.originalAuthor.profileId
          };
          
          // Add to batch
          const videoRef = db.collection('videos').doc();
          batch.set(videoRef, videoDoc);
        }
      }
      
      // Mark tweet as processed
      batch.update(snap.ref, { 
        isProcessed: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Commit all changes
      await batch.commit();
      
    } catch (error) {
      console.error('Error processing tweet:', error);
      // Mark as failed but processed to prevent infinite retries
      await snap.ref.update({ 
        isProcessed: true,
        processingError: error.message
      });
    }
  });
```

### Testing Implementation

```typescript
import * as functions from 'firebase-functions-test';
import * as admin from 'firebase-admin';
import { mockDeep } from 'jest-mock-extended';
import fetch from 'node-fetch';
import { onTweetCreated } from './functions'; // Import the actual Cloud Function

// Initialize Firebase Test environment
const testEnv = functions();
const db = admin.firestore();

// Mock oEmbed responses
const mockOembedResponses = {
  twitter: {
    html: '<a href="https://youtube.com/watch?v=test">Test Video</a>'
  },
  youtube: {
    title: 'Test YouTube Video',
    thumbnail_url: 'https://youtube.com/thumb.jpg',
    html: '<iframe src="https://youtube.com/embed/test"></iframe>',
    description: 'Test description'
  },
  loom: {
    title: 'Test Loom Video',
    thumbnail_url: 'https://loom.com/thumb.jpg',
    html: '<iframe src="https://loom.com/embed/test"></iframe>',
    description: 'Test description'
  }
};

describe('Tweet Processing Cloud Function', () => {
  const fetchMock = mockDeep<typeof fetch>();
  
  beforeAll(() => {
    // Mock fetch globally
    global.fetch = fetchMock;
  });

  beforeEach(async () => {
    // Clear all data before each test
    const collections = ['tweets', 'videos'];
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
    fetchMock.mockClear();
  });

  afterAll(async () => {
    // Clean up Firebase Test environment
    testEnv.cleanup();
  });

  it('processes YouTube video from tweet using Cloud Function', async () => {
    // Mock oEmbed responses
    fetchMock
      .mockResolvedValueOnce({ json: () => mockOembedResponses.twitter })
      .mockResolvedValueOnce({ json: () => mockOembedResponses.youtube });

    // Create test tweet document
    const tweetData = {
      urls: ['https://t.co/abc123'],
      originalAuthor: { profileId: 'test-user' },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Wrap the Cloud Function
    const wrapped = testEnv.wrap(onTweetCreated);

    // Create a snapshot of the document
    const snap = testEnv.firestore.makeDocumentSnapshot(
      tweetData,
      'tweets/test-tweet'
    );
    const context = testEnv.makeChange(snap);

    // Execute the Cloud Function
    await wrapped(snap, context);

    // Verify the results in Firestore
    const videos = await db.collection('videos')
      .where('tweetId', '==', 'test-tweet')
      .get();

    expect(videos.size).toBe(1);
    const video = videos.docs[0].data();
    expect(video.platform).toBe('youtube');
    expect(video.title).toBe('Test YouTube Video');
    expect(video.url).toBe('https://youtube.com/watch?v=test');

    // Verify tweet was marked as processed
    const processedTweet = await db.doc('tweets/test-tweet').get();
    expect(processedTweet.data().isProcessed).toBe(true);
  });

  it('processes Loom video from tweet using Cloud Function', async () => {
    fetchMock
      .mockResolvedValueOnce({ json: () => mockOembedResponses.twitter })
      .mockResolvedValueOnce({ json: () => mockOembedResponses.loom });

    const tweetData = {
      urls: ['https://t.co/xyz789'],
      originalAuthor: { profileId: 'test-user' },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const wrapped = testEnv.wrap(onTweetCreated);
    const snap = testEnv.firestore.makeDocumentSnapshot(
      tweetData,
      'tweets/test-tweet-loom'
    );
    const context = testEnv.makeChange(snap);

    await wrapped(snap, context);

    const videos = await db.collection('videos')
      .where('tweetId', '==', 'test-tweet-loom')
      .get();

    expect(videos.size).toBe(1);
    const video = videos.docs[0].data();
    expect(video.platform).toBe('loom');
    expect(video.title).toBe('Test Loom Video');
  });

  it('handles multiple videos in tweet using Cloud Function', async () => {
    fetchMock
      .mockResolvedValueOnce({ json: () => mockOembedResponses.twitter })
      .mockResolvedValueOnce({ json: () => mockOembedResponses.youtube })
      .mockResolvedValueOnce({ json: () => mockOembedResponses.twitter })
      .mockResolvedValueOnce({ json: () => mockOembedResponses.loom });

    const tweetData = {
      urls: ['https://t.co/abc123', 'https://t.co/xyz789'],
      originalAuthor: { profileId: 'test-user' },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const wrapped = testEnv.wrap(onTweetCreated);
    const snap = testEnv.firestore.makeDocumentSnapshot(
      tweetData,
      'tweets/test-tweet-multiple'
    );
    const context = testEnv.makeChange(snap);

    await wrapped(snap, context);

    const videos = await db.collection('videos')
      .where('tweetId', '==', 'test-tweet-multiple')
      .get();

    expect(videos.size).toBe(2);
    const platforms = videos.docs.map(doc => doc.data().platform);
    expect(platforms).toContain('youtube');
    expect(platforms).toContain('loom');
  });

  it('handles errors gracefully using Cloud Function', async () => {
    fetchMock.mockRejectedValueOnce(new Error('Network error'));

    const tweetData = {
      urls: ['https://invalid.url'],
      originalAuthor: { profileId: 'test-user' },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const wrapped = testEnv.wrap(onTweetCreated);
    const snap = testEnv.firestore.makeDocumentSnapshot(
      tweetData,
      'tweets/test-tweet-error'
    );
    const context = testEnv.makeChange(snap);

    await wrapped(snap, context);

    // Verify tweet was marked as processed with error
    const processedTweet = await db.doc('tweets/test-tweet-error').get();
    expect(processedTweet.data().isProcessed).toBe(true);
    expect(processedTweet.data().processingError).toBeDefined();

    // Verify no videos were created
    const videos = await db.collection('videos')
      .where('tweetId', '==', 'test-tweet-error')
      .get();
    expect(videos.size).toBe(0);
  });

  it('handles rate limiting from oEmbed providers', async () => {
    fetchMock
      .mockResolvedValueOnce({ json: () => mockOembedResponses.twitter })
      .mockRejectedValueOnce(new Error('Rate limit exceeded'));

    const tweetData = {
      urls: ['https://t.co/rate-limited'],
      originalAuthor: { profileId: 'test-user' },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const wrapped = testEnv.wrap(onTweetCreated);
    const snap = testEnv.firestore.makeDocumentSnapshot(
      tweetData,
      'tweets/test-tweet-rate-limit'
    );
    const context = testEnv.makeChange(snap);

    await wrapped(snap, context);

    const processedTweet = await db.doc('tweets/test-tweet-rate-limit').get();
    expect(processedTweet.data().isProcessed).toBe(true);
    expect(processedTweet.data().processingError).toContain('Rate limit');
  });
});
```

## Why This Approach?

1. **Simplicity:**
   - Single responsibility function
   - No additional infrastructure needed
   - Uses proven oEmbed standard
   - Easy to understand and maintain

2. **Reliability:**
   - Platform-maintained oEmbed endpoints
   - Built-in Firebase retries
   - Batch operations for consistency
   - Graceful error handling

3. **Testability:**
   - Easy to mock external services
   - Firebase Emulator support
   - Clear test scenarios
   - Isolated testing environment

4. **Cost-Effective:**
   - Uses existing Firebase infrastructure
   - No additional services required
   - Minimal processing overhead
   - Pay-per-use pricing

5. **Extensibility:**
   - Easy to add new platforms
   - Standardized metadata format
   - Clear extension points
   - Future-proof design

## References

- [oEmbed Specification](https://oembed.com/)
- [Twitter oEmbed API](https://developer.twitter.com/en/docs/twitter-api/v1/tweets/post-and-engage/api-reference/get-statuses-oembed)
- [YouTube oEmbed Documentation](https://developers.google.com/youtube/oembed)
- [Loom oEmbed Endpoint](https://www.loom.com/v1/oembed)
- [Firebase Testing](https://firebase.google.com/docs/rules/unit-tests)

---

This implementation provides a balance of simplicity, reliability, and maintainability while meeting our MVP requirements. The testing suite ensures the functionality works as expected and helps catch issues early in development.