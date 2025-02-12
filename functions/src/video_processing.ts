import * as functions from 'firebase-functions';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import fetch from 'node-fetch';

const db = getFirestore();

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
 * Cloud Function triggered on tweet creation to process video content
 */
export const onTweetCreated = functions.firestore
  .document('tweets/{tweetId}')
  .onCreate(async (snap, context) => {
    console.log('🔥 onTweetCreated function triggered with new data:', snap.data());
    const tweet = snap.data();
    console.log('Tweet URLs before filtering:', tweet.urls);
    // Filter URLs to only include those that start with http or https
    const urls = (tweet.urls || []).filter((url: string) => url.startsWith('http'));
    console.log('Tweet URLs after filtering:', urls);
    const batch = db.batch();
    let processedCount = 0;
    let errorCount = 0;
    
    try {
      console.log('Processing URLs:', urls);
      
      // Process each URL in the tweet
      for (const url of urls) {
        const metadata = await getVideoMetadata(url);
        
        if (metadata) {
          // Create video document with only defined values
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
            tweetId: context.params.tweetId,
            authorId: tweet.originalAuthor.profileId,
            ...(metadata.description && { description: metadata.description })  // Only include if defined
          };

          console.log(videoDoc);
          
          // Add to batch
          const videoRef = db.collection('videos').doc();
          batch.set(videoRef, videoDoc);
          processedCount++;
        } else {
          errorCount++;
        }
      }
      
      // Mark tweet as processed with status
      batch.update(snap.ref, { 
        isProcessed: true,
        processedAt: FieldValue.serverTimestamp(),
        processingSummary: {
          total: urls.length,  // Only count filtered URLs
          processed: processedCount,
          failed: errorCount
        }
      });
      
      // Commit all changes
      await batch.commit();
      
      console.log(`Successfully processed tweet ${context.params.tweetId}:`, {
        total: urls.length,
        processed: processedCount,
        failed: errorCount
      });
      
    } catch (error) {
      console.error(`Error processing tweet ${context.params.tweetId}:`, error);
      // Mark as failed but processed to prevent infinite retries
      await snap.ref.update({ 
        isProcessed: true,
        processedAt: FieldValue.serverTimestamp(),
        processingError: error instanceof Error ? error.message : 'Unknown error',
        processingSummary: {
          total: urls.length,  // Only count filtered URLs
          processed: processedCount,
          failed: urls.length - processedCount
        }
      });
    }
  }); 