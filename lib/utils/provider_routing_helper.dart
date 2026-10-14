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
  if (!profile.isProfileComplete) return AppDestination.completeProfile;

  final isApproved = profile.isVerified || isTechnicianApproved;
  final isNewProvider = profile.initialRole == 'provider' ||
      (profile.initialRole == null && profile.role == AppRole.provider);

  if (profile.role == AppRole.provider) {
    if (isApproved) {
      return AppDestination.providerDashboard;
    }
    if (isNewProvider) {
      return AppDestination.providerPendingNew;
    } else {
      return AppDestination.providerPendingCustomer;
    }
  }

  return AppDestination.homeDiscovery;
}
