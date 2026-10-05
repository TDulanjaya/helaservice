import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../models/admin_user.dart';
import '../state/role_provider.dart';
import '../constants/firestore_paths.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Map<String, UserProfile> _cachedProfiles = {};

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

  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    if (credential.user != null) {
      return await _resolveOrCreateProfile(credential.user!);
    }

    throw Exception('Authentication failed for $cleanEmail');
  }

  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    AppRole? role,
    String? phone,
    String? district,
    String? address,
    String? nic,
    String? nicFrontUrl,
    String? nicBackUrl,
    String? serviceCategory,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    if (credential.user != null) {
      final fbUser = credential.user!;
      await fbUser.updateDisplayName(displayName);

      final profile = UserProfile(
        id: fbUser.uid,
        email: cleanEmail,
        displayName: displayName,
        role: role,
        isProfileComplete: role != null,
        phone: phone,
        district: district,
        address: address,
        nic: nic,
        nicFrontUrl: nicFrontUrl,
        nicBackUrl: nicBackUrl,
        serviceCategory: serviceCategory,
      );

      return await saveUserProfile(profile);
    }

    throw Exception('Registration failed for $cleanEmail');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on fb.FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserProfile> signInWithGoogle() async {
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
      final doc = await userDocRef.get().timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!);
        _currentUser = profile;
        _cachedProfiles[uid] = profile;
        return profile;
      }
    } catch (_) {}

    final newProfile = UserProfile.fromFirebaseUser(fbUser);
    _currentUser = newProfile;
    _cachedProfiles[uid] = newProfile;

    try {
      await userDocRef.set(newProfile.toMap(), SetOptions(merge: true));
    } catch (_) {}

    return newProfile;
  }

  Future<UserProfile> saveUserProfile(UserProfile updatedProfile) async {
    final completed = updatedProfile.copyWith(isProfileComplete: true);
    final uid =
        completed.id.isNotEmpty ? completed.id : (_auth.currentUser?.uid ?? '');
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

        final techSnap = await techDoc.get();
        final bool isNewTech = !techSnap.exists;

        final Map<String, dynamic> techData = {
          'name': profileWithId.displayName,
          'initials': initials,
          'avatarColor': 0xFFD6900F,
          'title': profileWithId.serviceCategory != null
              ? '${profileWithId.serviceCategory} Specialist'
              : 'Service Technician',
          'online': true,
          'etaLabel': 'Available Today',
          'baseRateLkr': 1500,
          'responseTimeLabel': 'Usually responds in 10 mins',
          'yearsExperience': 'Verified',
          'serviceArea': profileWithId.district ?? 'Sri Lanka',
          'district': profileWithId.district,
          'latitude': profileWithId.latitude,
          'longitude': profileWithId.longitude,
          'phone': profileWithId.phone,
          'nic': profileWithId.nic,
          'nicFrontUrl': profileWithId.nicFrontUrl,
          'nicBackUrl': profileWithId.nicBackUrl,
        };

        if (isNewTech) {
          techData['nicVerified'] = false;
          techData['rating'] = 5.0;
          techData['reviewCount'] = 0;
          techData['jobsCount'] = 0;
          techData['banned'] = false;
          techData['isBanned'] = false;
        }

        batch.set(techDoc, techData, SetOptions(merge: true));

        if (profileWithId.nicFrontUrl != null ||
            profileWithId.nicBackUrl != null) {
          final verQueueDoc = FirebaseFirestore.instance
              .collection(FirestorePaths.verificationQueue)
              .doc(uid);
          final verSnap = await verQueueDoc.get();
          final bool docExists = verSnap.exists;
          final existingData = verSnap.data();
          final existingStatus = existingData?['status'] as String?;

          // Only submit for review if new or previously rejected with new photos.
          bool shouldQueue = false;
          if (!docExists) {
            shouldQueue = true;
          } else if (existingStatus == 'rejected') {
            final oldFront = existingData?['nicFrontUrl'] as String?;
            final oldBack = existingData?['nicBackUrl'] as String?;
            if (profileWithId.nicFrontUrl != oldFront ||
                profileWithId.nicBackUrl != oldBack) {
              shouldQueue = true;
            }
          }

          if (shouldQueue) {
            batch.set(
              verQueueDoc,
              {
                'providerId': uid,
                'providerName': profileWithId.displayName,
                'serviceCategory': profileWithId.serviceCategory,
                'phone': profileWithId.phone,
                'district': profileWithId.district,
                'nic': profileWithId.nic,
                'nicFrontUrl': profileWithId.nicFrontUrl,
                'nicBackUrl': profileWithId.nicBackUrl,
                'status': 'pending',
                'submittedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      }

      await batch.commit().timeout(const Duration(seconds: 10));
    }

    _currentUser = profileWithId;
    _cachedProfiles[uid] = profileWithId;
    return profileWithId;
  }

  Future<void> updateUserField(String uid, Map<String, dynamic> fields) async {
    try {
      if (uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(uid)
            .set(fields, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> createAdminAccount({
    required String email,
    required String displayName,
    required AdminRole role,
    required List<AdminPermission> permissions,
    String? phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final currentUid = _auth.currentUser?.uid ?? '';

    final usersSnap = await FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (usersSnap.docs.isEmpty) {
      throw Exception(
        'No registered user found with email "$cleanEmail". The person must first register an account in the app before they can be promoted to an administrator.',
      );
    }

    final targetUid = usersSnap.docs.first.id;
    final existingAdminSnap = await FirebaseFirestore.instance
        .collection(FirestorePaths.admins)
        .doc(targetUid)
        .get();

    if (existingAdminSnap.exists) {
      throw Exception('User is already registered as an administrator.');
    }

    await FirebaseFirestore.instance
        .collection(FirestorePaths.admins)
        .doc(targetUid)
        .set({
      'id': targetUid,
      'email': cleanEmail,
      'displayName': displayName.trim().isNotEmpty
          ? displayName.trim()
          : (usersSnap.docs.first.data()['displayName'] ?? 'Admin'),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'role': role.key,
      'status': 'active',
      'permissions': permissions.map((p) => p.key).toList(),
      'createdBy': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'uid': targetUid,
      'email': cleanEmail,
      'displayName': displayName,
    };
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
      }
    } catch (_) {}
    _currentUser = null;
    _cachedProfiles.clear();
  }

  static String getReadableAuthError(dynamic error) {
    if (error is fb.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please check your spelling or register.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect password or email. Please check your credentials.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment before trying again.';
        case 'network-request-failed':
          return 'Network connection issue. Please check your internet connection.';
        default:
          return error.message ?? error.code;
      }
    }
    final str = error.toString().replaceFirst('Exception: ', '');
    return str;
  }
}
