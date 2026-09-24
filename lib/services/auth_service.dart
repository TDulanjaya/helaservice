import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../state/role_provider.dart';
import '../constants/firestore_paths.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  fb.ConfirmationResult? _webConfirmationResult;

  final Map<String, UserProfile> _userStore = {
    'customer.sample@gmail.com': const UserProfile(
      id: 'g_cust_101',
      email: 'customer.sample@gmail.com',
      displayName: 'Sanduni Perera',
      photoUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&auto=format&fit=crop&q=80',
      role: AppRole.customer,
      isProfileComplete: true,
      phone: '+94771234567',
      district: 'Colombo',
      address: 'No. 12, Flower Road, Colombo 07',
    ),
    'provider.sample@gmail.com': const UserProfile(
      id: 'g_pro_202',
      email: 'provider.sample@gmail.com',
      displayName: 'Sunil Bandara',
      photoUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=120&auto=format&fit=crop&q=80',
      role: AppRole.provider,
      isProfileComplete: true,
      phone: '+94714567890',
      district: 'Gampaha',
      nic: '198812345678',
      serviceCategory: 'Electrical',
    ),
    '+94771234567': const UserProfile(
      id: 'p_cust_303',
      email: 'sanduni.phone@helaservice.lk',
      displayName: 'Sanduni Perera',
      photoUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&auto=format&fit=crop&q=80',
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

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

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

  Future<UserProfile> signInWithGoogle({String? testEmail}) async {
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
        photoUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
        role: null,
        isProfileComplete: false,
      );
      _currentUser = newUser;
      _userStore[testEmail] = newUser;
      return newUser;
    }

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

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
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

      return await _resolveOrCreateProfile(fbUser);
    } catch (e) {
      rethrow;
    }
  }

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
              final profile =
                  await _resolveOrCreateProfile(userCredential.user!);
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
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(_readableAuthError(e));
    }
  }

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
      throw Exception(
          'Verification succeeded, but user profile could not be loaded.');
    }

    return await _resolveOrCreateProfile(fbUser);
  }

  Future<UserProfile?> fetchCurrentUserProfile() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return await _resolveOrCreateProfile(fbUser);
  }

  Future<UserProfile> _resolveOrCreateProfile(fb.User fbUser) async {
    final uid = fbUser.uid;
    final userDocRef =
        FirebaseFirestore.instance.collection(FirestorePaths.users).doc(uid);

    try {
      final doc = await userDocRef.get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!);
        _currentUser = profile;
        _userStore[uid] = profile;
        return profile;
      }
    } catch (_) {
      if (_userStore.containsKey(uid)) {
        _currentUser = _userStore[uid]!;
        return _currentUser!;
      }
    }

    final newProfile = UserProfile.fromFirebaseUser(fbUser);
    _currentUser = newProfile;
    _userStore[uid] = newProfile;

    try {
      await userDocRef.set(newProfile.toMap(), SetOptions(merge: true));
    } catch (_) {}

    return newProfile;
  }

  Future<UserProfile> saveUserProfile(UserProfile updatedProfile) async {
    final completed = updatedProfile.copyWith(isProfileComplete: true);
    final uid = completed.id.isNotEmpty
        ? completed.id
        : (_auth.currentUser?.uid ?? '');
    final profileWithId = completed.copyWith(id: uid);

    if (uid.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();

      final userDoc =
          FirebaseFirestore.instance.collection(FirestorePaths.users).doc(uid);
      batch.set(userDoc, profileWithId.toMap(), SetOptions(merge: true));

      if (profileWithId.role == AppRole.provider) {
        final techDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(uid);

        final initials = profileWithId.displayName.isNotEmpty
            ? profileWithId.displayName
                .split(' ')
                .where((e) => e.isNotEmpty)
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
            : 'SP';

        batch.set(
          techDoc,
          {
            'name': profileWithId.displayName,
            'initials': initials,
            'avatarColor': 0xFF00685F,
            'title': profileWithId.serviceCategory != null
                ? '${profileWithId.serviceCategory} Specialist'
                : 'Service Technician',
            'nicVerified': false,
            'online': true,
            'rating': 5.0,
            'reviewCount': 0,
            'etaLabel': 'Available Today',
            'baseRateLkr': 1500,
            'responseTimeLabel': 'Usually responds in 10 mins',
            'jobsCount': 0,
            'yearsExperience': 'Verified',
            'serviceArea': profileWithId.district ?? 'Sri Lanka',
            'phone': profileWithId.phone,
            'nic': profileWithId.nic,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    }

    _currentUser = profileWithId;
    _userStore[uid] = profileWithId;
    return profileWithId;
  }

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
