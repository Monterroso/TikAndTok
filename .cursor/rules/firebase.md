---
description: 
globs: 
---
# Firebase Emulator Rules

## Description
Rules for handling Firebase emulator operations and testing in our TikTok clone project.

## Globs
- functions/**/*.ts
- functions/**/*.js

## Context
The project uses Firebase emulators for local development:
- Firestore emulator runs on port 8080
- Functions emulator runs on port 5001

## Rules

### Emulator Verification
Before running any Firebase-related commands or tests:
1. Check if Firestore emulator is running on port 8080
2. Check if Functions emulator is running on port 5001
3. Ensure the project ID matches 'tikandtok-684cb'

### Test Video Creation
When creating test videos:
1. Verify emulators are running
2. Use the test_video_trigger.ts script
3. Ensure proper error handling and cleanup
4. Check for successful creation in Firestore
5. Verify the video analysis trigger is working

### Common Issues
- If emulators aren't running, suggest starting them with `firebase emulators:start --only functions,firestore`
- If connection fails, verify ports 8080 and 5001 are available
- If project ID mismatch occurs, ensure using 'tikandtok-684cb' 