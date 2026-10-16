import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../models/admin_user.dart';
import '../state/role_provider.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../constants/firestore_paths.dart';
import '../utils/provider_location_helper.dart';
import '../utils/provider_pricing_helper.dart';
import 'live_location_service.dart';
import 'provider_tracking_service.dart';

// sign in errors shown by the ui
class AuthFlowException implements Exception {
  // google email has no account
  static const String googleNoAccount = 'GOOGLE_NO_ACCOUNT';

  // profile could not load
  static const String network = 'NETWORK';

  final String code;
  const AuthFlowException(this.code);

  @override
  String toString() => code;
}

// what google sign in should do next
enum GoogleSignInDecision {
  // has profile sign in
  proceed,

  // new account from login page delete it
  rejectNewAccount,

  // old account without profile sign out
  rejectMissingProfile,

  // register page create profile
  createProfile,
}

GoogleSignInDecision decideGoogleSignIn({
  required bool allowCreate,
  required bool isNewUser,
  required bool profileExists,
}) {
  if (!allowCreate && isNewUser) return GoogleSignInDecision.rejectNewAccount;
  if (profileExists) return GoogleSignInDecision.proceed;
  if (!allowCreate) return GoogleSignInDecision.rejectMissingProfile;
  return GoogleSignInDecision.createProfile;
}

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
      return (await _resolveOrCreateProfile(credential.user!,
          allowCreate: true))!;
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
    String? nicFrontKey,
    String? nicBackKey,
    String? nicFrontUrl,
    String? nicBackUrl,
    String? serviceCategory,
    int? dailyRateLkr,
    int? hourlyRateLkr,
    int? perKmRateLkr,
    int? visitFeeLkr,
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
        nicFrontKey: nicFrontKey ?? nicFrontUrl,
        nicBackKey: nicBackKey ?? nicBackUrl,
        serviceCategory: serviceCategory,
        dailyRateLkr: dailyRateLkr,
        hourlyRateLkr: hourlyRateLkr,
        perKmRateLkr: perKmRateLkr,
        visitFeeLkr: visitFeeLkr,
      );

      return await saveUserProfile(profile, markComplete: false);
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

  // google sign in login page cannot create accounts
  Future<UserProfile> signInWithGoogle({required bool allowCreate}) async {
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
          message: 'ERROR_ABORTED_BY_USER',
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

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    // new account on login page
    if (decideGoogleSignIn(
          allowCreate: allowCreate,
          isNewUser: isNewUser,
          profileExists: false,
        ) ==
        GoogleSignInDecision.rejectNewAccount) {
      await _discardNewGoogleAccount(fbUser);
      throw const AuthFlowException(AuthFlowException.googleNoAccount);
    }

    Map<String, dynamic>? data;
    try {
      data = await _readUserData(fbUser.uid);
    } on AuthFlowException {
      if (!allowCreate) await signOut();
      rethrow;
    }

    final decision = decideGoogleSignIn(
      allowCreate: allowCreate,
      isNewUser: isNewUser,
      profileExists: data != null,
    );
    if (decision == GoogleSignInDecision.proceed) {
      return await _profileFromData(fbUser.uid, data!);
    }
    if (decision == GoogleSignInDecision.createProfile) {
      return await _createProfile(fbUser);
    }

    // no profile on login page
    await signOut();
    throw const AuthFlowException(AuthFlowException.googleNoAccount);
  }

  // delete account made by login page
  Future<void> _discardNewGoogleAccount(fb.User fbUser) async {
    try {
      await fbUser.delete();
    } catch (e) {
      debugPrint('[AuthService] Could not delete new Google account: $e');
    }
    await signOut();
  }

  // load current profile without creating
  Future<UserProfile?> fetchCurrentUserProfile({
    bool throwOnNetwork = false,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      return await _resolveOrCreateProfile(fbUser, allowCreate: false);
    } on AuthFlowException {
      if (throwOnNetwork) rethrow;
      return _cachedProfiles[fbUser.uid];
    }
  }

  static const Duration _profileReadTimeout = Duration(seconds: 10);

  // read user doc from server or cache
  Future<Map<String, dynamic>?> _readUserData(String uid) async {
    final ref =
        FirebaseFirestore.instance.collection(FirestorePaths.users).doc(uid);

    // normal read
    try {
      final snap = await ref.get().timeout(_profileReadTimeout);
      final data = snap.data();
      if (snap.exists && data != null) return data;
      if (!snap.metadata.isFromCache) return null; // not on server
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') rethrow;
      debugPrint('[AuthService] Profile read failed: ${e.code}');
    } catch (e) {
      debugPrint('[AuthService] Profile read failed: $e');
    }

    // retry from server
    try {
      final snap = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(_profileReadTimeout);
      final data = snap.data();
      return (snap.exists && data != null) ? data : null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') rethrow;
      debugPrint('[AuthService] Profile server read failed: ${e.code}');
    } catch (e) {
      debugPrint('[AuthService] Profile server read failed: $e');
    }

    throw const AuthFlowException(AuthFlowException.network);
  }

  Future<UserProfile> _profileFromData(
      String uid, Map<String, dynamic> data) async {
    await _migrateCustomerLocationIfNeeded(uid, data);
    var profile = UserProfile.fromMap(data);

    try {
      final locDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('private')
          .doc('location')
          .get()
          .timeout(const Duration(seconds: 2));
      if (locDoc.exists && locDoc.data() != null) {
        final locData = locDoc.data()!;
        final pLat = (locData['latitude'] as num?)?.toDouble();
        final pLng = (locData['longitude'] as num?)?.toDouble();
        if (pLat != null && pLng != null) {
          profile = profile.copyWith(
            latitude: pLat,
            longitude: pLng,
          );
        }
      }
    } catch (_) {}

    _currentUser = profile;
    _cachedProfiles[uid] = profile;
    return profile;
  }

  Future<UserProfile> _createProfile(fb.User fbUser) async {
    final newProfile = UserProfile.fromFirebaseUser(fbUser);
    _currentUser = newProfile;
    _cachedProfiles[fbUser.uid] = newProfile;

    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(fbUser.uid)
          .set(newProfile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AuthService] Profile create failed: $e');
    }

    return newProfile;
  }

  // load profile or create if allowed
  Future<UserProfile?> _resolveOrCreateProfile(
    fb.User fbUser, {
    required bool allowCreate,
  }) async {
    final data = await _readUserData(fbUser.uid);
    if (data != null) return await _profileFromData(fbUser.uid, data);
    if (!allowCreate) return null;
    return await _createProfile(fbUser);
  }

  Future<void> _migrateCustomerLocationIfNeeded(
      String uid, Map<String, dynamic> data) async {
    final roleStr = data['role'] as String?;
    // skip if role is empty or user has admin access
    if (roleStr == null || roleStr == 'provider') return;
    if ((data['serviceCategory'] as String?)?.trim().isNotEmpty == true) return;
    if ((data['nic'] as String?)?.trim().isNotEmpty == true) return;

    final firestore = FirebaseFirestore.instance;

    // skip migration if user is technician or admin
    try {
      final checks = await Future.wait([
        firestore.collection('technicians').doc(uid).get(),
        firestore.collection('superAdmins').doc(uid).get(),
        firestore.collection('admins').doc(uid).get(),
      ]).timeout(const Duration(seconds: 2));
      if (checks.any((doc) => doc.exists)) return;
    } catch (e) {
      debugPrint(
          '[AuthService] Provider/Admin check error: $e. Aborting migration for retry.');
      return;
    }

    final rawLat = data['latitude'];
    final rawLng = data['longitude'];
    final hasAddress = data.containsKey('address') && data['address'] != null;
    final hasDistrict =
        data.containsKey('district') && data['district'] != null;

    if (rawLat == null && rawLng == null && !hasAddress && !hasDistrict) {
      return;
    }

    try {
      final double? lat = (rawLat is num) ? rawLat.toDouble() : null;
      final double? lng = (rawLng is num) ? rawLng.toDouble() : null;

      bool hasRealCoordinates = false;
      if (lat != null &&
          lng != null &&
          lat.isFinite &&
          lng.isFinite &&
          lat != 0.0 &&
          lng != 0.0) {
        final isColomboDefault =
            (lat - 6.9271).abs() < 0.0001 && (lng - 79.8612).abs() < 0.0001;
        if (!isColomboDefault) {
          hasRealCoordinates = true;
        }
      }

      final batch = firestore.batch();
      final userDocRef = firestore.collection(FirestorePaths.users).doc(uid);

      if (hasRealCoordinates) {
        final savedCol = userDocRef.collection('savedAddresses');
        final existing =
            await savedCol.where('label', isEqualTo: 'Home').limit(1).get();

        if (existing.docs.isEmpty) {
          final address =
              (data['address'] as String?)?.trim().isNotEmpty == true
                  ? (data['address'] as String).trim()
                  : ((data['district'] as String?)?.trim().isNotEmpty == true
                      ? data['district'] as String
                      : 'home');

          final newAddrRef = savedCol.doc();
          batch.set(newAddrRef, {
            'label': 'home',
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'landmark': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // remove old location fields from customer record
      batch.update(userDocRef, {
        'latitude': FieldValue.delete(),
        'longitude': FieldValue.delete(),
        'address': FieldValue.delete(),
        'district': FieldValue.delete(),
      });

      await batch.commit();

      // update memory profile to match database
      data.remove('latitude');
      data.remove('longitude');
      data.remove('address');
      data.remove('district');
    } catch (e) {
      debugPrint('[AuthService] Customer location migration error: $e');
    }
  }

  Future<UserProfile> saveUserProfile(
    UserProfile updatedProfile, {
    bool markComplete = true,
  }) async {
    if (kDebugMode) {
      final trace =
          StackTrace.current.toString().split('\n').take(8).join('\n');
      debugPrint(
          '[navdbg] saveUserProfile called (markComplete=$markComplete):\n$trace');
    }
    final completed = markComplete
        ? updatedProfile.copyWith(isProfileComplete: true)
        : updatedProfile;
    final uid =
        completed.id.isNotEmpty ? completed.id : (_auth.currentUser?.uid ?? '');
    final profileWithId = completed.copyWith(id: uid);

    if (uid.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      bool shouldQueue = false;

      final userDoc =
          FirebaseFirestore.instance.collection(FirestorePaths.users).doc(uid);
      final userMap = profileWithId.toMap();
      if (profileWithId.pricingModes != null) {
        if (!profileWithId.pricingModes!
                .contains(ProviderPricingHelper.modeHour) ||
            (profileWithId.hourlyRateLkr ?? 0) <= 0) {
          userMap['hourlyRateLkr'] = FieldValue.delete();
        }
        if (!profileWithId.pricingModes!
                .contains(ProviderPricingHelper.modeDay) ||
            (profileWithId.dailyRateLkr ?? 0) <= 0) {
          userMap['dailyRateLkr'] = FieldValue.delete();
        }
        if (!profileWithId.pricingModes!
                .contains(ProviderPricingHelper.modeTravel) ||
            (profileWithId.perKmRateLkr ?? 0) <= 0) {
          userMap['perKmRateLkr'] = FieldValue.delete();
        }
        if (!profileWithId.pricingModes!
                .contains(ProviderPricingHelper.modeVisit) ||
            (profileWithId.visitFeeLkr ?? 0) <= 0) {
          userMap['visitFeeLkr'] = FieldValue.delete();
        }
      } else {
        if ((profileWithId.hourlyRateLkr ?? 0) <= 0 &&
            profileWithId.hourlyRateLkr != null) {
          userMap['hourlyRateLkr'] = FieldValue.delete();
        }
        if ((profileWithId.dailyRateLkr ?? 0) <= 0 &&
            profileWithId.dailyRateLkr != null) {
          userMap['dailyRateLkr'] = FieldValue.delete();
        }
        if ((profileWithId.perKmRateLkr ?? 0) <= 0 &&
            profileWithId.perKmRateLkr != null) {
          userMap['perKmRateLkr'] = FieldValue.delete();
        }
        if ((profileWithId.visitFeeLkr ?? 0) <= 0 &&
            profileWithId.visitFeeLkr != null) {
          userMap['visitFeeLkr'] = FieldValue.delete();
        }
      }
      batch.set(userDoc, userMap, SetOptions(merge: true));

      // save exact coords privately
      if (profileWithId.latitude != null && profileWithId.longitude != null) {
        final locDoc = userDoc.collection('private').doc('location');
        batch.set(
          locDoc,
          {
            'latitude': profileWithId.latitude,
            'longitude': profileWithId.longitude,
            if (profileWithId.address != null) 'address': profileWithId.address,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

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
          'title': profileWithId.serviceCategory ?? '',
          'category': profileWithId.serviceCategory ?? '',
          'serviceCategory': profileWithId.serviceCategory ?? '',
          'online': true,
          'etaLabel': '',
          'responseTimeLabel': '',
          'yearsExperience': '',
          'serviceArea': profileWithId.district ?? '',
          'district': profileWithId.district,
          'phone': profileWithId.phone,
          if (profileWithId.pricingModes != null)
            'pricingModes': profileWithId.pricingModes,
          if (profileWithId.latitude != null &&
              profileWithId.longitude != null) ...{
            'latitude': roundToTwoDecimals(profileWithId.latitude!),
            'longitude': roundToTwoDecimals(profileWithId.longitude!),
            'baseLat': roundToTwoDecimals(profileWithId.latitude!),
            'baseLng': roundToTwoDecimals(profileWithId.longitude!),
            if (profileWithId.address != null &&
                profileWithId.address!.trim().isNotEmpty)
              'baseAddress': profileWithId.address!.trim(),
          },
          if (profileWithId.dailyRateLkr != null &&
              profileWithId.dailyRateLkr! > 0 &&
              (profileWithId.pricingModes == null ||
                  profileWithId.pricingModes!
                      .contains(ProviderPricingHelper.modeDay)))
            'dailyRateLkr': profileWithId.dailyRateLkr
          else if (!isNewTech)
            'dailyRateLkr': FieldValue.delete(),
          if (profileWithId.hourlyRateLkr != null &&
              profileWithId.hourlyRateLkr! > 0 &&
              (profileWithId.pricingModes == null ||
                  profileWithId.pricingModes!
                      .contains(ProviderPricingHelper.modeHour)))
            'hourlyRateLkr': profileWithId.hourlyRateLkr
          else if (!isNewTech)
            'hourlyRateLkr': FieldValue.delete(),
          if (profileWithId.perKmRateLkr != null &&
              profileWithId.perKmRateLkr! > 0 &&
              (profileWithId.pricingModes == null ||
                  profileWithId.pricingModes!
                      .contains(ProviderPricingHelper.modeTravel)))
            'perKmRateLkr': profileWithId.perKmRateLkr
          else if (!isNewTech)
            'perKmRateLkr': FieldValue.delete(),
          if (profileWithId.visitFeeLkr != null &&
              profileWithId.visitFeeLkr! > 0 &&
              (profileWithId.pricingModes == null ||
                  profileWithId.pricingModes!
                      .contains(ProviderPricingHelper.modeVisit)))
            'visitFeeLkr': profileWithId.visitFeeLkr
          else if (!isNewTech)
            'visitFeeLkr': FieldValue.delete(),
        };

        if (isNewTech) {
          techData['nicVerified'] = false;
          techData['rating'] = null;
          techData['reviewCount'] = 0;
          techData['jobsCount'] = 0;
          techData['banned'] = false;
          techData['isBanned'] = false;
        }

        batch.set(techDoc, techData, SetOptions(merge: true));

        // store private kyc details
        if (profileWithId.nic != null ||
            profileWithId.nicFrontKey != null ||
            profileWithId.nicBackKey != null) {
          final kycDoc = techDoc.collection('private').doc('kyc');
          batch.set(
            kycDoc,
            {
              if (profileWithId.nic != null) 'nic': profileWithId.nic,
              if (profileWithId.nicFrontKey != null)
                'nicFrontKey': profileWithId.nicFrontKey,
              if (profileWithId.nicBackKey != null)
                'nicBackKey': profileWithId.nicBackKey,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        if (profileWithId.nicFrontKey != null ||
            profileWithId.nicBackKey != null) {
          final verQueueDoc = FirebaseFirestore.instance
              .collection(FirestorePaths.verificationQueue)
              .doc(uid);
          final verSnap = await verQueueDoc.get();
          final bool docExists = verSnap.exists;
          final existingData = verSnap.data();
          final existingStatus = existingData?['status'] as String?;

          // queue review on changes
          if (!docExists) {
            shouldQueue = true;
          } else if (existingStatus == 'rejected' ||
              existingStatus == 'resubmit') {
            shouldQueue = true;
          } else {
            final oldFront = existingData?['nicFrontKey'] as String? ??
                existingData?['nicFrontUrl'] as String?;
            final oldBack = existingData?['nicBackKey'] as String? ??
                existingData?['nicBackUrl'] as String?;
            if (profileWithId.nicFrontKey != oldFront ||
                profileWithId.nicBackKey != oldBack) {
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
                'nicFrontKey': profileWithId.nicFrontKey,
                'nicBackKey': profileWithId.nicBackKey,
                'status': 'pending',
                'submittedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      }

      await batch.commit().timeout(const Duration(seconds: 10));

      if (shouldQueue) {
        // request server nic hash
        await requestNicHash();
      }
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
          : (usersSnap.docs.first.data()['displayName'] ?? 'ADMIN'),
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

  // request server nic hash calculation
  Future<void> requestNicHash() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await user.getIdToken();
      final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/nic-hash');

      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-helaservice-key': AppConfig.apiSecretKey,
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        debugPrint(
            '[nic-hash] non-200 response: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      // submit errors are ignored
      debugPrint('[nic-hash] request error: $e');
    }
  }

  // delete account permanently
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await user.getIdToken();
      final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/delete-account');

      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-helaservice-key': AppConfig.apiSecretKey,
        },
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('remote delete account note: $e');
    }

    try {
      await user.delete();
    } catch (_) {}

    await signOut();
  }

  Future<void> signOut() async {
    try {
      LiveLocationService.instance.stopTracking();
      ProviderTrackingService.instance.stopOnlineTracking();
    } catch (_) {}
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
      return error.code;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
