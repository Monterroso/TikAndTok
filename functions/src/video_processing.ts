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
  authorId: string;
}

interface BatchProcessingMessage {
  batchId: string;
  timestamp: string;
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
      // Query tweets from this batch
      const tweetsSnapshot = await db.collection('tweets')
        .where('batchId', '==', data.batchId)
        .where('isProcessed', '==', false)
        .get();

      if (tweetsSnapshot.empty) {
        console.log(`No unprocessed tweets found in batch ${data.batchId}`);
        return;
      }

      console.log(`Processing ${tweetsSnapshot.size} tweets from batch ${data.batchId}`);
      const batch = db.batch();
      let processedCount = 0;
      let errorCount = 0;

      // Process each tweet in the batch
      for (const tweetDoc of tweetsSnapshot.docs) {
        const tweet = tweetDoc.data();
        const urls = (tweet.urls || []).filter((url: string) => url.startsWith('http'));
        
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
              authorId: tweet.originalAuthor.username,
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