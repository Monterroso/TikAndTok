import * as functions from 'firebase-functions';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import fetch from 'node-fetch';
import { VertexAI } from '@google-cloud/vertexai';

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
  tweetId?: string;
  userId: string;
  analysis?: VideoAnalysis;
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
 * Interfaces for technical analysis
 */
interface VideoAnalysis {
  // Required fields matching Flutter model
  implementationOverview?: string;
  technicalDetails?: string;
  techStack: string[];
  architecturePatterns: string[];
  bestPractices: string[];
  isProcessing: boolean;
  error?: string;
  lastUpdated: Timestamp;

  // Additional fields for backend processing
  _internal?: {
    processingMetadata?: {
      startTime: Timestamp;
      attempts: number;
      lastError?: string;
    };
    rawAnalysis?: {
      geminiResponse?: string;
      confidence?: number;
      processingDuration?: number;
    };
  };
}

// Add Gemini configuration
const PROJECT_ID = 'tikandtok-684cb';  // Your GCP project ID
const LOCATION = 'us-central1';    // Your model location

// Initialize Vertex AI with Gemini Pro Vision model for video analysis
const vertexAI = new VertexAI({project: PROJECT_ID, location: LOCATION});
const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-pro-vision',  // Changed to vision model for video analysis
  generationConfig: {
    maxOutputTokens: 2048,
    temperature: 0.4,
    topP: 0.8,
    topK: 40,
  },
});

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

/**
 * Fetches video content from Firebase Storage
 */
async function fetchVideoContent(url: string): Promise<Buffer> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch video: ${response.statusText}`);
    }
    return Buffer.from(await response.arrayBuffer());
  } catch (error) {
    console.error('Error fetching video content:', error);
    throw error;
  }
}

/**
 * Clean array items by:
 * 1. Removing any descriptive headers
 * 2. Removing markdown bullets and whitespace
 * 3. Filtering out empty items
 */
function cleanArrayItems(items: string[]): string[] {
  if (!Array.isArray(items)) return [];
  
  return items
    .filter(item => item && typeof item === 'string')
    // Remove items that look like headers or descriptions
    .filter(item => !item.toLowerCase().includes('including:') && !item.toLowerCase().includes('such as:'))
    // Clean up markdown bullets and whitespace
    .map(item => item.replace(/^[*•-]\s*/, '').trim())
    // Filter out empty strings
    .filter(item => item.length > 0);
}

/**
 * Analyzes video content using Gemini
 * @param videoData - The video document data
 * @returns Promise resolving to structured analysis
 */
async function analyzeVideoContent(videoData: FirebaseFirestore.DocumentData): Promise<Partial<VideoAnalysis>> {
  try {
    console.log('Fetching video content...');
    const videoContent = await fetchVideoContent(videoData.url);

    const prompt = `You are analyzing a technical showcase video.
Title: ${videoData.title}
${videoData.description ? `Description: ${videoData.description}\n` : ''}

Please analyze the video content and provide a detailed technical analysis including:
1. A clear overview of the implementation shown
2. The technical stack used (identify programming languages, frameworks, libraries seen in the video)
3. Architecture patterns demonstrated in the code or explained
4. Best practices shown or discussed
5. Any specific technical challenges and solutions presented

Format the response as a JSON object with these fields:
{
  "implementationOverview": "Clear explanation of what was implemented",
  "technicalDetails": "Detailed technical analysis",
  "techStack": ["technology1", "technology2"],
  "architecturePatterns": ["pattern1", "pattern2"],
  "bestPractices": ["practice1", "practice2"]
}

Important formatting rules:
- Arrays should contain ONLY the items themselves, no descriptions or headers
- Do not use bullet points or markdown formatting
- Each array item should be a simple string
- Do not include numbering or prefixes in array items

Return ONLY the JSON object, no additional text or formatting.`;

    console.log('Sending to Gemini for analysis...');
    const result = await model.generateContent({
      contents: [{
        role: 'user',
        parts: [
          { text: prompt },
          { inlineData: { 
            mimeType: 'video/mp4',
            data: videoContent.toString('base64')
          }}
        ]
      }]
    });
    
    const response = await result.response;
    if (!response.candidates?.[0]?.content?.parts) {
      throw new Error('Invalid response format from Gemini');
    }
    
    const text = response.candidates[0].content.parts
      .map(part => part.text)
      .join('');
    
    // Clean up the response text by removing any markdown formatting
    const cleanText = text.replace(/```json\n|\n```/g, '').trim();
    
    // Parse the analysis text into structured format
    let analysis: any;
    try {
      analysis = JSON.parse(cleanText);
    } catch (e) {
      console.error('Failed to parse Gemini response as JSON:', e);
      console.log('Raw response:', text);
      
      // If JSON parsing fails, attempt to structure the response
      const sections = text.split('\n\n');
      analysis = {
        implementationOverview: sections[0] || '',
        technicalDetails: sections[1] || '',
        techStack: extractTechStack(text),
        architecturePatterns: extractPatterns(text),
        bestPractices: extractBestPractices(text)
      };
    }
    
    // Ensure all arrays are properly initialized and cleaned
    const finalAnalysis: Partial<VideoAnalysis> = {
      implementationOverview: analysis.implementationOverview || '',
      technicalDetails: analysis.technicalDetails || '',
      techStack: cleanArrayItems(analysis.techStack),
      architecturePatterns: cleanArrayItems(analysis.architecturePatterns),
      bestPractices: cleanArrayItems(analysis.bestPractices),
      isProcessing: false,
      lastUpdated: Timestamp.now(),
      _internal: {
        processingMetadata: {
          startTime: Timestamp.now(),
          attempts: 1,
        },
        rawAnalysis: {
          geminiResponse: text,
          confidence: 0.95,
          processingDuration: Date.now() - Date.now(), // Will be set properly in the main function
        }
      }
    };

    return finalAnalysis;
  } catch (error) {
    console.error('Error analyzing video content:', error);
    throw error;
  }
}

// Helper functions to extract structured data from text if JSON parsing fails
function extractTechStack(text: string): string[] {
  const techMatches = text.match(/(?:tech stack|technologies?|using|built with|implemented with)[:]\s*([^.]*)/gi);
  if (!techMatches) return [];
  
  return techMatches
    .flatMap(match => match.split(/[,:]/).slice(1))
    .map(tech => tech.trim())
    .filter(tech => tech.length > 0);
}

function extractPatterns(text: string): string[] {
  const patternMatches = text.match(/(?:patterns?|architecture)[:]\s*([^.]*)/gi);
  if (!patternMatches) return [];
  
  return patternMatches
    .flatMap(match => match.split(/[,:]/).slice(1))
    .map(pattern => pattern.trim())
    .filter(pattern => pattern.length > 0);
}

function extractBestPractices(text: string): string[] {
  const practiceMatches = text.match(/(?:best practices|practices)[:]\s*([^.]*)/gi);
  if (!practiceMatches) return [];
  
  return practiceMatches
    .flatMap(match => match.split(/[,:]/).slice(1))
    .map(practice => practice.trim())
    .filter(practice => practice.length > 0);
}

export const processVideoWithGemini = functions.firestore
  .document('videos/{videoId}')
  .onCreate(async (snap, context) => {
    const videoId = context.params.videoId;
    const videoData = snap.data();
    const db = getFirestore();
    const startTime = Date.now();
    console.log(`Starting technical analysis for video: ${videoId}`);
    console.log('Video data:', JSON.stringify(videoData, null, 2));

    try {
      // Initialize processing state
      console.log('Initializing processing state...');
      const initialState: VideoAnalysis = {
        implementationOverview: "Initializing technical analysis...",
        technicalDetails: "Analysis in progress",
        techStack: [],
        architecturePatterns: [],
        bestPractices: [],
        isProcessing: true,
        lastUpdated: Timestamp.now(),
        _internal: {
          processingMetadata: {
            startTime: Timestamp.now(),
            attempts: 1,
          }
        }
      };
      
      await db.collection('video_analysis').doc(videoId).set(initialState);
      console.log('Processing state initialized');

      // Perform analysis with Gemini
      console.log('Starting Gemini analysis...');
      const analysis = await analyzeVideoContent(videoData);
      
      // Add processing duration
      if (analysis._internal?.rawAnalysis) {
        analysis._internal.rawAnalysis.processingDuration = Date.now() - startTime;
      }

      // Store the analysis
      await db.collection('video_analysis').doc(videoId).set(analysis);
      console.log('Analysis stored successfully');

    } catch (error) {
      console.error('Error processing video:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      
      // Update analysis with error state
      await db.collection('video_analysis').doc(videoId).set({
        implementationOverview: 'Error during technical analysis',
        technicalDetails: errorMessage,
        techStack: [],
        architecturePatterns: [],
        bestPractices: [],
        isProcessing: false,
        error: errorMessage,
        lastUpdated: Timestamp.now(),
        _internal: {
          processingMetadata: {
            startTime: Timestamp.now(),
            attempts: 1,
            lastError: errorMessage
          }
        }
      });
    }
  });

export const handleTechnicalDiscussion = functions.firestore
  .document('videos/{videoId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const { videoId, commentId } = context.params;
    const commentData = snap.data();
    const { text } = commentData;
    const db = getFirestore();

    // Only proceed if comment contains "just submit"
    if (!text.toLowerCase().includes('just submit')) {
      return;
    }

    console.log(`Processing technical implementation question for video ${videoId}`);

    try {
      // Get analysis from video_analysis collection
      const analysisDoc = await db.collection('video_analysis').doc(videoId).get();
      if (!analysisDoc.exists) {
        throw new Error('Technical analysis not found');
      }

      const analysis = analysisDoc.data() as VideoAnalysis;
      if (analysis.isProcessing) {
        throw new Error('Technical analysis is still processing');
      }
      if (analysis.error) {
        throw new Error(`Technical analysis failed: ${analysis.error}`);
      }

      // Generate response using the analysis data
      const response = `Technical Implementation Analysis:

${analysis.implementationOverview ? `Overview:
${analysis.implementationOverview}

` : ''}${analysis.techStack.length > 0 ? `Tech Stack:
${analysis.techStack.map((tech: string) => `• ${tech}`).join('\n')}

` : ''}${analysis.architecturePatterns.length > 0 ? `Architecture Patterns:
${analysis.architecturePatterns.map((pattern: string) => `• ${pattern}`).join('\n')}

` : ''}${analysis.technicalDetails ? `Technical Details:
${analysis.technicalDetails}

` : ''}${analysis.bestPractices.length > 0 ? `Best Practices:
${analysis.bestPractices.map((practice: string) => `• ${practice}`).join('\n')}

` : ''}Feel free to ask for more specific details about any aspect of the implementation.`;

      // Add response as a regular reply comment
      await db.collection('videos').doc(videoId)
        .collection('comments').add({
          text: response,
          userId: 'system',
          parentId: commentId,
          createdAt: Timestamp.now(),
        });

      console.log('Technical implementation details provided successfully');

    } catch (error) {
      console.error('Error providing technical implementation details:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      
      // Add error response as a comment
      await db.collection('videos').doc(videoId)
        .collection('comments').add({
          text: `Sorry, I couldn't provide technical implementation details: ${errorMessage}`,
          userId: 'system',
          parentId: commentId,
          createdAt: Timestamp.now(),
        });
    }
  }); 