import * as functions from 'firebase-functions';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import fetch from 'node-fetch';

const tweet_batch_topic = 'tweet_batch_processed';

/**
 * Interfaces for API responses
 */
interface OEmbedResponse {
  title: string;
  thumbnail_url: string;
  description?: string;
}

/**
 * Interfaces for video metadata and documents
 */
export interface VideoMetadata {
  url: string;
  thumbnailUrl: string;
  title: string;
  platform: 'youtube' | 'loom';
  description?: string;
}

export interface VideoDocument extends VideoMetadata {
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  likedBy: string[];
  savedBy: string[];
  comments: number;
  tweetId: string;
  userId: string;
}

interface BatchProcessingMessage {
  batchId: string;
  timestamp: string;
}

interface UserProfile {
  username: string;
  email?: string;
  bio: string;
  photoURL: string;
  createdAt: FieldValue;
  updatedAt: FieldValue;
}

/**
 * Resolve a potentially shortened URL to its final destination
 * @param url - The URL to resolve
 * @returns The resolved URL or the original if resolution fails
 */
async function resolveUrl(url: string): Promise<string> {
  if (url.includes('t.co') || url.includes('bit.ly') || url.includes('goo.gl')) {
    try {
      const response = await fetch(url, { 
        redirect: 'follow',
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; TikTokClone/1.0)'
        }
      });
      return response.url;
    } catch (error) {
      console.error('Error resolving shortened URL:', error);
      return url;
    }
  }
  return url;
}

/**
 * Get video metadata using oEmbed
 * @param url - The URL to fetch metadata for
 * @returns Promise resolving to VideoMetadata or null if not supported/available
 */
export async function getVideoMetadata(url: string): Promise<VideoMetadata | null> {
  try {
    // First, resolve any shortened URLs
    const resolvedUrl = await resolveUrl(url);
    console.log('Processing URL:', resolvedUrl);
    
    const lowerUrl = resolvedUrl.toLowerCase();
    
    // Handle YouTube videos
    if (lowerUrl.includes('youtube.com') || lowerUrl.includes('youtu.be')) {
      const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(resolvedUrl)}&format=json`;
      const response = await fetch(oembedUrl);
      
      if (!response.ok) {
        console.error('YouTube oEmbed request failed:', await response.text());
        return null;
      }

      const data = await response.json() as OEmbedResponse;
      
      return {
        url: resolvedUrl,
        thumbnailUrl: data.thumbnail_url,
        title: data.title || 'Untitled Video',
        platform: 'youtube',
        ...(data.description ? { description: data.description } : {})
      };
    }
    
    // Handle Loom videos
    if (lowerUrl.includes('loom.com')) {
      const oembedUrl = `https://www.loom.com/v1/oembed?url=${encodeURIComponent(resolvedUrl)}`;
      const response = await fetch(oembedUrl);
      
      if (!response.ok) {
        console.error('Loom oEmbed request failed:', await response.text());
        return null;
      }

      const data = await response.json() as OEmbedResponse;
      
      return {
        url: resolvedUrl,
        thumbnailUrl: data.thumbnail_url,
        title: data.title || 'Untitled Video',
        platform: 'loom',
        ...(data.description ? { description: data.description } : {})
      };
    }
    
    console.warn('URL not from supported platform:', resolvedUrl);
    return null;
  } catch (error) {
    console.error('Error fetching video metadata:', error);
    return null;
  }
}

/**
 * Find or create a user profile by username
 * @param db - Firestore instance
 * @param username - Username to look up
 * @returns The user's ID
 */
async function findOrCreateUser(db: FirebaseFirestore.Firestore, username: string): Promise<string> {
  // First try to find the user by username
  const usersSnapshot = await db.collection('users')
    .where('username', '==', username)
    .limit(1)
    .get();

  // If user exists, return their ID
  if (!usersSnapshot.empty) {
    return usersSnapshot.docs[0].id;
  }

  // User doesn't exist, create a new profile
  console.log(`Creating new user profile for username: ${username}`);
  const newUserRef = db.collection('users').doc();
  const userProfile: UserProfile = {
    username: username,
    bio: '',
    photoURL: '',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp()
  };

  await newUserRef.set(userProfile);
  console.log(`Created new user with ID: ${newUserRef.id}`);
  return newUserRef.id;
}

/**
 * Cloud Function triggered by Pub/Sub when a batch of tweets is ready for processing.
 * This function listens to messages from the tweet_batch_processed topic, which are
 * published after tweet batches are saved to Firestore.
 */
export const processTweetBatch = functions.pubsub
  .topic(tweet_batch_topic)
  .onPublish(async (message) => {
    const db = getFirestore();
    const data = message.json as BatchProcessingMessage;
    console.log('Processing tweet batch:', data);

    try {
      // First get all tweets from this batch to check their status
      const allTweetsSnapshot = await db.collection('tweets')
        .where('batchId', '==', data.batchId)
        .get();

      console.log(`Found ${allTweetsSnapshot.size} total tweets in batch ${data.batchId}`);
      
      if (allTweetsSnapshot.empty) {
        console.log('No tweets found at all for this batch. This could mean:');
        console.log('1. The tweets have not been saved yet (race condition)');
        console.log('2. The batchId is incorrect');
        console.log('3. The tweets were saved to a different collection');
        return;
      }

      // Log details about each tweet
      allTweetsSnapshot.docs.forEach(doc => {
        const tweet = doc.data();
        console.log(`Tweet ${doc.id} - isProcessed: ${tweet.isProcessed}, processingStatus: ${tweet.processingStatus || 'undefined'}`);
      });

      // Query tweets from this batch that are not processed
      const tweetsSnapshot = await db.collection('tweets')
        .where('batchId', '==', data.batchId)
        .where('isProcessed', '==', false)
        .get();

      if (tweetsSnapshot.empty) {
        console.log(`No unprocessed tweets found in batch ${data.batchId}. This could mean either:`);
        console.log('1. All tweets are already processed');
        console.log('2. The isProcessed field is undefined instead of false');
        console.log('3. The tweets have not been saved yet');
        return;
      }

      console.log(`Processing ${tweetsSnapshot.size} unprocessed tweets from batch ${data.batchId}`);
      const batch = db.batch();
      let processedCount = 0;
      let errorCount = 0;

      // Process each tweet in the batch
      for (const tweetDoc of tweetsSnapshot.docs) {
        const tweet = tweetDoc.data();
        const urls = (tweet.urls || []).filter((url: string) => url.startsWith('http'));
        
        // Get or create user before processing URLs
        const userId = await findOrCreateUser(db, tweet.originalAuthor.username);
        console.log(`Using user ID: ${userId} for username: ${tweet.originalAuthor.username}`);
        
        // Process each URL in the tweet
        for (const url of urls) {
          const metadata = await getVideoMetadata(url);
          
          if (metadata) {
            // Create video document
            const videoDoc: VideoDocument = {
              url: metadata.url,
              thumbnailUrl: metadata.thumbnailUrl,
              title: metadata.title,
              platform: metadata.platform,
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
              likedBy: [],
              savedBy: [],
              comments: 0,
              tweetId: tweetDoc.id,
              userId: userId,
              ...(metadata.description && { description: metadata.description })
            };

            // Add to batch
            const videoRef = db.collection('videos').doc();
            batch.set(videoRef, videoDoc);
            processedCount++;
          } else {
            console.error(`Error processing video metadata for URL: ${url}, metadata: ${metadata}`);
            errorCount++;
          }
        }

        // Mark tweet as processed
        batch.update(tweetDoc.ref, {
          isProcessed: true,
          processingStatus: 'completed',
          processedAt: FieldValue.serverTimestamp(),
          processingSummary: {
            total: urls.length,
            processed: processedCount,
            failed: errorCount
          }
        });
      }

      // Commit all changes
      await batch.commit();

      console.log(`Successfully processed batch ${data.batchId}:`, {
        tweets: tweetsSnapshot.size,
        videos: processedCount,
        errors: errorCount
      });

    } catch (error) {
      console.error(`Error processing batch ${data.batchId}:`, error);
      // We should implement a dead-letter queue or retry mechanism here
      // For now, we'll just log the error
      throw error; // This will trigger Pub/Sub's retry mechanism
    }
  }); 