import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class to handle all authentication related operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user getter
  User? get currentUser => _auth.currentUser;

  /// Check if user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Sign in with email and password
  Future<UserCredential> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!credential.user!.emailVerified) {
        await signOutUser();
        throw 'Please verify your email before signing in. Check your inbox for the verification link.';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found for that email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'user-disabled':
          throw 'This user has been disabled.';
        case 'invalid-email':
          throw 'The email address is not valid.';
        default:
          throw 'An error occurred while signing in: ${e.message}';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /// Sign up with email and password
  Future<void> signUpUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await credential.user?.sendEmailVerification();
      
      // Sign out until email is verified
      await signOutUser();
      
      throw 'Please check your email to verify your account before signing in.';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw 'The password provided is too weak.';
        case 'email-already-in-use':
          throw 'An account already exists for that email.';
        case 'invalid-email':
          throw 'The email address is not valid.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        default:
          throw 'An error occurred while signing up: ${e.message}';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user is currently signed in.';
      if (user.emailVerified) throw 'Email is already verified.';
      
      await user.sendEmailVerification();
    } catch (e) {
      throw 'Failed to resend verification email: $e';
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Google sign in was cancelled.';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'An account already exists with the same email address but different sign-in credentials.';
        case 'invalid-credential':
          throw 'The credential is malformed or has expired.';
        case 'operation-not-allowed':
          throw 'Google sign-in is not enabled.';
        case 'user-disabled':
          throw 'This user has been disabled.';
        case 'user-not-found':
          throw 'No user found for that email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-verification-code':
          throw 'The verification code is invalid.';
        case 'invalid-verification-id':
          throw 'The verification ID is invalid.';
        default:
          throw 'An error occurred while signing in with Google: ${e.message}';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /// Sign out user
  Future<void> signOutUser() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'An error occurred while signing out: $e';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw 'The email address is not valid.';
        case 'user-not-found':
          throw 'No user found for that email.';
        default:
          throw 'An error occurred while sending password reset email: ${e.message}';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
