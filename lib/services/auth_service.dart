import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/errors/app_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current user stream — listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user details from Firestore
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken removed in google_sign_in v7 — idToken alone is sufficient for Firebase Auth
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createOrUpdateUser(userCredential.user!);
      return await getUser(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e.code));
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'account-exists-with-different-credential' => 'This account already exists with a different sign-in method.',
      'invalid-credential' => 'The sign-in credentials are invalid.',
      'operation-not-allowed' => 'Google sign-in is not enabled for this project.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No user found for this account.',
      'wrong-password' => 'Wrong password.',
      _ => 'Google sign-in failed. Please try again.',
    };
  }

  // Step 1: Send OTP
  Future<void> sendOTP({
    required String phoneNumber,       // format: +919876543210
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function(PhoneAuthCredential) onAutoVerified,
  }) async {
    // Rate limit check BEFORE calling Firebase
    final isRateLimited = await _checkOtpRateLimit(phoneNumber);
    if (isRateLimited) {
      onError('Too many attempts. Please wait 10 minutes.');
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      
      // Android auto-reads SMS and verifies automatically
      verificationCompleted: onAutoVerified,
      
      // OTP sent — store verificationId for step 2
      codeSent: (verificationId, forceResendingToken) {
        _incrementOtpAttempt(phoneNumber);  // Track attempt
        onCodeSent(verificationId);
      },
      
      verificationFailed: (FirebaseAuthException e) {
        final message = switch (e.code) {
          'invalid-phone-number' => 'Invalid phone number',
          'too-many-requests'    => 'Too many attempts. Try later.',
          'quota-exceeded'       => 'Service limit reached. Try later.',
          _                      => 'Something went wrong. Try again.',
        };
        onError(message);
      },
      
      codeAutoRetrievalTimeout: (_) {}, // No action needed
    );
  }

  // Step 2: Verify OTP
  Future<UserModel?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final userCred = await _auth.signInWithCredential(credential);
      
      // Create or update user in Firestore
      await _createOrUpdateUser(userCred.user!);
      return await getUser(userCred.user!.uid);
      
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'invalid-verification-code' => const AppException('Wrong OTP. Check and try again.'),
        'session-expired'           => const AppException('OTP expired. Request a new one.'),
        _                           => const AppException('Verification failed. Try again.'),
      };
    }
  }

  // Create user doc on first login, update lastSeen on subsequent logins
  Future<void> _createOrUpdateUser(User firebaseUser) async {
    final ref = _db.collection('users').doc(firebaseUser.uid);
    final doc = await ref.get();
    
    if (!doc.exists) {
      await ref.set({
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? '',
        'phone': firebaseUser.phoneNumber ?? '',
        'photoUrl': firebaseUser.photoURL ?? '',
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? '',
        'photoUrl': firebaseUser.photoURL ?? '',
        'provider': 'google',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Rate limiting: store attempts in SharedPreferences
  // In production: move this to Cloud Functions for stronger security
  Future<bool> _checkOtpRateLimit(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'otp_attempts_$phone';
    final timeKey = 'otp_window_$phone';
    
    final windowStart = prefs.getInt(timeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final tenMinutes = 10 * 60 * 1000;
    
    if (now - windowStart > tenMinutes) {
      // Reset window
      await prefs.setInt(timeKey, now);
      await prefs.setInt(key, 0);
      return false;
    }
    
    final attempts = prefs.getInt(key) ?? 0;
    return attempts >= 3;  // Block after 3 attempts in 10 min
  }

  Future<void> _incrementOtpAttempt(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'otp_attempts_$phone';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  Future<void> updateUserProfile({required String name, required String phone}) async {
    final user = _auth.currentUser;
    if (user == null) throw const AppException('User not logged in');

    await _db.collection('users').doc(user.uid).update({
      'name': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const AppException('User not logged in');

    try {
      // Delete user document from Firestore
      await _db.collection('users').doc(user.uid).delete();
      
      // Delete user from Firebase Auth
      await user.delete();
      
      // Sign out from Google if applicable
      await GoogleSignIn.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AppException('Please log out and log back in to delete your account.');
      }
      throw AppException(e.message ?? 'Failed to delete account');
    } catch (e) {
      throw AppException('An error occurred while deleting account');
    }
  }
}
