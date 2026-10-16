import '../models/user_profile.dart';
import '../state/role_provider.dart';

// navigation destinations
enum AppDestination {
  login,
  emailOtp,
  roleChoice,
  completeProfile,
  homeDiscovery,
  providerDashboard,
  providerPendingNew,
  providerPendingCustomer,
  adminShell,
}

// check if user signup is incomplete
bool isSignupUnfinished(UserProfile p) {
  return !p.isProfileComplete;
}

// check if new provider is waiting for approval
bool isLockedNewProvider(UserProfile p, bool isApproved) {
  return p.role == AppRole.provider &&
      !isApproved &&
      !p.isVerified &&
      p.initialRole != 'customer';
}

// pick screen from role and approval
AppDestination resolveAppDestination({
  required UserProfile? profile,
  required bool isAuthorizedAdmin,
  required bool isEmailOtpVerified,
  bool isTechnicianApproved = false,
}) {
  if (profile == null) return AppDestination.login;
  if (!isEmailOtpVerified) return AppDestination.emailOtp;
  if (isAuthorizedAdmin) return AppDestination.adminShell;
  if (profile.role == null) return AppDestination.roleChoice;
  if (isSignupUnfinished(profile)) return AppDestination.completeProfile;

  final isApproved = profile.isVerified || isTechnicianApproved;

  if (profile.role == AppRole.provider) {
    if (isApproved) {
      return AppDestination.providerDashboard;
    }
    if (isLockedNewProvider(profile, isApproved)) {
      return AppDestination.providerPendingNew;
    } else {
      return AppDestination.providerPendingCustomer;
    }
  }

  return AppDestination.homeDiscovery;
}
