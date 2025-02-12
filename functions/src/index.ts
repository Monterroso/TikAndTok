/**
 * Import function triggers from their respective submodules:
 *
 * Note: Auth triggers are only supported in v1
 * See: https://firebase.google.com/docs/functions/auth-events
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Initialize Firebase Admin first
admin.initializeApp();

// Import functions that need Firebase Admin
import { onTweetCreated } from './video_processing';

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * Cloud Function to create a user profile in Firestore when a new auth user
 * is created. This function extracts basic user info from Firebase Auth,
 * sets default profile fields, and writes them into a new document under
 * the 'users' collection.
 */
export const createUserProfile = functions.auth
  .user()
  .onCreate((user: admin.auth.UserRecord) => {
    const {uid, email, displayName, photoURL} = user;

    // Derive a default username from displayName (fallback to empty string)
    const username = displayName ?
      displayName.replace(/\s+/g, "_").toLowerCase() :
      "";

    const defaultProfile = {
      email: email || "",
      username: username,
      bio: "",
      photoURL: photoURL || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    try {
      return admin.firestore()
        .collection("users")
        .doc(uid)
        .set(defaultProfile)
        .then(() => {
          logger.info(`User profile created for uid: ${uid}`);
        })
        .catch((error) => {
          logger.error(`Error creating user profile for uid: ${uid}`, error);
          throw error; // Re-throw to ensure Firebase knows this function failed
        });
    } catch (error) {
      logger.error(`Error creating user profile for uid: ${uid}`, error);
      throw error;
    }
  });

export { onTweetCreated };
