import 'dart:async';
import '../models/user_profile.dart';
import '../../state/role_provider.dart';

/// Authentication Service
/// Handles Google Sign-In and profile persistence.
/// Currently configured with a testable local store and realistic mock data for frontend testing,
/// and prepared for drop-in Firebase Auth / Google Sign-In integration.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // In-memory cache of registered profiles (keyed by user email/id)
  final Map<String, UserProfile> _userStore = {
    // Pre-registered customer example
    'customer.sample@gmail.com': const UserProfile(
      id: 'g_cust_101',
      email: 'customer.sample@gmail.com',
      displayName: 'Sanduni Perera',
      photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&auto=format&fit=crop&q=80',
      role: AppRole.customer,
      isProfileComplete: true,
      phone: '771234567',
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
      phone: '714567890',
      district: 'Gampaha',
      nic: '198812345678',
      serviceCategory: 'Electrical',
    ),
  };

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  /// Simulates Google Sign-In OAuth flow.
  /// When connecting to real Firebase Auth / Google Sign In in production:
  /// ```dart
  /// final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  /// final GoogleSignInAuthentication googleAuth = await googleUser?.authentication;
  /// final credential = GoogleAuthProvider.credential(
  ///   accessToken: googleAuth?.accessToken,
  ///   idToken: googleAuth?.idToken,
  /// );
  /// final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
  /// ```
  Future<UserProfile> signInWithGoogle({String? testEmail}) async {
    // Simulate OAuth network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final email = testEmail ?? 'kasun.fernando95@gmail.com';

    // Check if user already exists in storage
    if (_userStore.containsKey(email)) {
      _currentUser = _userStore[email]!;
      return _currentUser!;
    }

    // New Google account (no role or address chosen yet)
    final newUser = UserProfile(
      id: 'g_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: 'Kasun Fernando',
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=80',
      role: null,
      isProfileComplete: false,
    );

    _currentUser = newUser;
    return newUser;
  }

  /// Updates and completes the user's profile with chosen role and required details
  Future<UserProfile> saveUserProfile(UserProfile updatedProfile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final completed = updatedProfile.copyWith(isProfileComplete: true);
    _userStore[completed.email] = completed;
    _currentUser = completed;
    return completed;
  }

  void signOut() {
    _currentUser = null;
  }
}
