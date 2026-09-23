import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../../state/role_provider.dart';

/// Authentication Service
/// Handles Firebase Authentication (Google Sign-In & Phone OTP verification),
/// session management, and user profile persistence.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Web-only confirmation result for Phone OTP
  fb.ConfirmationResult? _webConfirmationResult;

  // In-memory cache of registered profiles (keyed by user email, phone, or id)
  final Map<String, UserProfile> _userStore = {
    // Pre-registered customer example
    'customer.sample@gmail.com': const UserProfile(
      id: 'g_cust_101',
      email: 'customer.sample@gmail.com',
      displayName: 'Sanduni Perera',
      photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&auto=format&fit=crop&q=80',
      role: AppRole.customer,
      isProfileComplete: true,
      phone: '+94771234567',
      district: 'Colombo',
      address: 'No. 12, Flower Road, Colombo 07',
    ),
    // Pre-registered provider example
    'provider.sample@gmail.com': const UserProfile(
      id: 'g_pro_202',
      email: 'provider.sample@gmail.com',
      displayName: 'Sunil Bandara',
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=120&auto=format&fit=crop&q=80',
      role: AppRole.provider,
      isProfileComplete: true,
      phone: '+94714567890',
      district: 'Gampaha',
      nic: '198812345678',
      serviceCategory: 'Electrical',
    ),
    // Sample phone user
    '+94771234567': const UserProfile(
      id: 'p_cust_303',
      email: 'sanduni.phone@helaservice.lk',
      displayName: 'Sanduni Perera',
      photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&auto=format&fit=crop&q=80',
      role: AppRole.customer,
      isProfileComplete: true,
      phone: '+94771234567',
      district: 'Colombo',
      address: 'No. 12, Flower Road, Colombo 07',
    ),
  };

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  fb.User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of Firebase Auth state changes
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  /// Formats raw input into an E.164 Sri Lankan phone number (+94XXXXXXXXX)
  static String formatSriLankanPhoneNumber(String input) {
    String clean = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (clean.startsWith('+94')) {
      return clean;
    }
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    if (clean.startsWith('94')) {
      return '+$clean';
    }
    return '+94$clean';
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Initiates Google Sign-In with Firebase Auth.
  /// If [testEmail] is provided, uses local mocked persona for quick offline/UI testing.
  Future<UserProfile> signInWithGoogle({String? testEmail}) async {
    // 1. Check if test persona is explicitly selected
    if (testEmail != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_userStore.containsKey(testEmail)) {
        _currentUser = _userStore[testEmail]!;
        return _currentUser!;
      }
      final newUser = UserProfile(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: testEmail,
        displayName: 'Kasun Fernando',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
        role: null,
        isProfileComplete: false,
      );
      _currentUser = newUser;
      _userStore[testEmail] = newUser;
      return newUser;
    }

    // 2. Production Firebase Google Sign-In
    try {
      fb.UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = fb.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw fb.FirebaseAuthException(
            code: 'ERROR_ABORTED_BY_USER',
            message: 'Sign-in cancelled by user.',
          );
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final fb.User? fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Firebase user data is not available.');
      }

      return _resolveOrCreateProfile(fbUser);
    } catch (e) {
      // If error occurs, rethrow clean exception
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Phone Number OTP Authentication
  // ---------------------------------------------------------------------------

  /// Sends a one-time SMS verification code to [phoneNumber].
  /// Calls [onCodeSent] with the `verificationId` when the SMS is dispatched.
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(UserProfile user)? onAutoVerified,
  }) async {
    final formatted = formatSriLankanPhoneNumber(phoneNumber);

    if (kIsWeb) {
      try {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(formatted);
        onCodeSent('web_confirmation_id');
      } catch (e) {
        onError(_readableAuthError(e));
      }
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formatted,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              final profile = _resolveOrCreateProfile(userCredential.user!);
              if (onAutoVerified != null) {
                onAutoVerified(profile);
              }
            }
          } catch (e) {
            onError(_readableAuthError(e));
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          onError(_readableAuthError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto retrieval timed out; user will enter code manually
        },
      );
    } catch (e) {
      onError(_readableAuthError(e));
    }
  }

  /// Verifies the 6-digit SMS OTP against Firebase Auth.
  Future<UserProfile> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    fb.UserCredential userCredential;

    if (kIsWeb && _webConfirmationResult != null) {
      userCredential = await _webConfirmationResult!.confirm(smsCode);
    } else {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    final fb.User? fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Verification succeeded, but user profile could not be loaded.');
    }

    return _resolveOrCreateProfile(fbUser);
  }

  // ---------------------------------------------------------------------------
  // Profile Management & Helper Methods
  // ---------------------------------------------------------------------------

  UserProfile _resolveOrCreateProfile(fb.User fbUser) {
    final emailKey = fbUser.email;
    final phoneKey = fbUser.phoneNumber;
    final idKey = fbUser.uid;

    if (emailKey != null && _userStore.containsKey(emailKey)) {
      _currentUser = _userStore[emailKey]!;
      return _currentUser!;
    }

    if (phoneKey != null && _userStore.containsKey(phoneKey)) {
      _currentUser = _userStore[phoneKey]!;
      return _currentUser!;
    }

    if (_userStore.containsKey(idKey)) {
      _currentUser = _userStore[idKey]!;
      return _currentUser!;
    }

    final newProfile = UserProfile.fromFirebaseUser(fbUser);
    _currentUser = newProfile;
    if (emailKey != null && emailKey.isNotEmpty) _userStore[emailKey] = newProfile;
    if (phoneKey != null && phoneKey.isNotEmpty) _userStore[phoneKey] = newProfile;
    _userStore[idKey] = newProfile;
    return newProfile;
  }

  /// Updates and completes the user's profile with chosen role and required details
  Future<UserProfile> saveUserProfile(UserProfile updatedProfile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final completed = updatedProfile.copyWith(isProfileComplete: true);

    if (completed.email.isNotEmpty) {
      _userStore[completed.email] = completed;
    }
    if (completed.phone != null && completed.phone!.isNotEmpty) {
      _userStore[completed.phone!] = completed;
    }
    _userStore[completed.id] = completed;

    _currentUser = completed;
    return completed;
  }

  /// Signs the user out from both Firebase and Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    _currentUser = null;
    _webConfirmationResult = null;
  }

  String _readableAuthError(dynamic error) {
    if (error is fb.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'The phone number is not valid. Please enter a valid Sri Lankan mobile number.';
        case 'invalid-verification-code':
          return 'The 6-digit verification code you entered is invalid. Please check and try again.';
        case 'session-expired':
          return 'The verification code has expired. Please request a new OTP.';
        case 'quota-exceeded':
          return 'SMS quota exceeded for today. Please try again later or use test credentials.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment before trying again.';
        default:
          return error.message ?? error.code;
      }
    }
    return error.toString();
  }
}
