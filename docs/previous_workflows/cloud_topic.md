# Tweet Processing System Architecture with Google Cloud Pub/Sub

## Topic Name and Structure
- Topic name: tweet_batch_processed
- Message format: JSON containing { batchId: string, timestamp: string }
- Messages are published after each successful batch save to Firestore

## Tweet Document Structure
interface Tweet {
    id: string;
    batchId: string;  // Links tweets to specific processing batch
    profileId: string;  // User who retweeted
    scrapeSessionId: string;
    originalAuthor: {
        username: string;
        displayName: string;
    };
    repostedBy?: {
        username: string;
        displayName: string;
    };
    text: string;
    urls: string[];
    timestamp: Date;
    engagement: {
        retweets: number;
        likes: number;
        replies: number;
    };
    media: {
        type: 'image' | 'video';
        url: string;
    }[];
    url: string;
    scrapedAt: Date;
}

## Publishing Process
- After scraping tweets, they're saved to Firestore with a unique batchId
- A message is immediately published to the Pub/Sub topic
- The PubSub client is initialized in the constructor of the RetweetScraper class
- Messages are published using the publishBatchProcessedEvent method

## Cloud Function Requirements
- Triggers on messages to tweet_batch_processed topic
- Needs Firestore read/write permissions
- Should handle retries automatically
- Must process tweets in batches for efficiency
- Should group processing by user

## Processing Steps
### Message Receipt
- Decode Pub/Sub message
- Extract batchId and timestamp
- Validate message contents

### Tweet Retrieval
- Query Firestore for tweets with matching batchId
- Group tweets by user (profileId)

### Per-User Processing
- Update user statistics
- Process media content
- Calculate engagement metrics
- Mark tweets as processed

### Batch Completion
- Record processing status
- Handle any errors
- Update processing metadata

## Error Handling
- Failed processing should be retried
- Errors should be logged with batch and tweet IDs
- Processing status should be tracked in Firestore

## Required Permissions
- Pub/Sub publisher role for the scraper
- Pub/Sub subscriber role for the Cloud Function
- Firestore read/write access

## Dependencies
import { PubSub } from '@google-cloud/pubsub';
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

## Environment Setup
- Google Cloud project must be configured
- Pub/Sub topic must be created
- Cloud Functions must be deployed
- Firebase Admin SDK must be initialized

## Performance Considerations
- Process tweets in parallel where possible
- Use batch operations for Firestore updates
- Implement timeouts for long-running operations
- Consider memory limits of Cloud Functions

## Monitoring
- Track successful/failed batches
- Monitor processing times
- Log important events and errors
- Track resource usage

This system allows for scalable, reliable processing of tweet batches with proper error handling and monitoring capabilities. The decoupled architecture ensures that tweet scraping and processing can operate independently and efficiently.

## Example Implementation Details

### Publishing a Message
private async publishBatchProcessedEvent(batchId: string): Promise<void> {
    const topicName = 'tweet_batch_processed';
    const messagePayload = {
        batchId,
        timestamp: new Date().toISOString()
    };
    const dataBuffer = Buffer.from(JSON.stringify(messagePayload));
    await this.pubsub.topic(topicName).publish(dataBuffer);
}

### Cloud Function Structure
export const processTweetBatchPubSub = functions.pubsub
    .topic('tweet_batch_processed')
    .onPublish(async (message: functions.pubsub.Message) => {
        const data = message.json;
        const { batchId, timestamp } = data;
        
        // Query tweets from this batch
        const tweetsSnapshot = await db.collection('tweets')
            .where('batchId', '==', batchId)
            .get();
            
        // Process tweets...
        // Update user statistics...
        // Handle media...
});

### Batch Processing
const batch = db.batch();
tweets.forEach(tweet => {
    batch.update(db.collection('tweets').doc(tweet.id), {
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp()
    });
});
await batch.commit();

This architecture provides a robust foundation for processing tweet data asynchronously while maintaining scalability and reliability. The system can be extended to handle additional processing requirements as needed.