import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;

import '../../../constants/firestore_paths.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../screens/nic_verification_screen.dart';

class ProviderApprovalGate extends StatefulWidget {
  final Widget child;

  const ProviderApprovalGate({
    super.key,
    required this.child,
  });

  @override
  State<ProviderApprovalGate> createState() => _ProviderApprovalGateState();
}

class _ProviderApprovalGateState extends State<ProviderApprovalGate> {
  bool _hasEverBeenUnapproved = false;
  bool _hasShownCelebration = false;

  void _showCelebrationModal(BuildContext context) {
    if (_hasShownCelebration) return;
    _hasShownCelebration = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 42,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.proApprovalGrantedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.themeInk,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.proApprovalGrantedDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.l10n.proGetStarted,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    if (roleProvider.isAuthorizedAdmin) {
      return widget.child;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return widget.child;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(uid)
          .snapshots(),
      builder: (context, techSnap) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestorePaths.verificationQueue)
              .doc(uid)
              .snapshots(),
          builder: (context, queueSnap) {
            final techData = techSnap.data?.data();
            final queueData = queueSnap.data?.data();

            final bool techApproved = techData?['nicVerified'] == true ||
                techData?['isVerified'] == true;
            final String? queueStatus = queueData?['status'] as String?;
            final bool queueApproved = queueStatus == 'approved';

            final bool isApproved = techApproved || queueApproved;

            if (!isApproved) {
              _hasEverBeenUnapproved = true;
            } else if (_hasEverBeenUnapproved && !_hasShownCelebration) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showCelebrationModal(context);
              });
            }

            return Stack(
              children: [
                AbsorbPointer(
                  absorbing: !isApproved,
                  child: widget.child,
                ),
                if (!isApproved)
                  _buildLockOverlay(
                    context,
                    uid: uid,
                    queueStatus: queueStatus,
                    isRejected: queueStatus == 'rejected',
                    isPending: queueStatus == 'pending',
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLockOverlay(
    BuildContext context, {
    required String uid,
    required String? queueStatus,
    required bool isRejected,
    required bool isPending,
  }) {
    final isDark = context.isDark;
    final cardBg = isDark ? context.themeSurface : Colors.white;

    final String statusLabel = isPending
        ? context.l10n.proStatusPendingReview
        : (isRejected
            ? context.l10n.proStatusRejected
            : context.l10n.proStatusActionRequired);

    final Color statusColor = isPending
        ? AppColors.primary
        : (isRejected ? AppColors.error : const Color(0xFFF59E0B));

    final IconData statusIcon = isPending
        ? Icons.hourglass_top_rounded
        : (isRejected ? Icons.cancel_outlined : Icons.shield_outlined);

    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final isCustomerHistory =
        roleProvider.currentUser?.initialRole == 'customer';

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: (isDark ? Colors.black : Colors.black87)
              .withValues(alpha: isDark ? 0.65 : 0.45),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: SingleChildScrollView(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? context.themeBorder : Colors.white24,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCustomerHistory)
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: context.themeTextSecondary,
                            tooltip: context.l10n.backToCustomerDashboard,
                            onPressed: () {
                              if (kDebugMode) {
                                debugPrint(
                                    '[navdbg] -> customer home from provider_approval_gate.dart');
                              }
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const HomeDiscoveryScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 6),
                      // animated badge icon
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            statusIcon,
                            size: 38,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // title
                      Text(
                        context.l10n.proApprovalRequiredTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: context.themeInk,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // description
                      Text(
                        context.l10n.proApprovalRequiredDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // submit button
                      PrimaryButton(
                        label: isPending
                            ? context.l10n.proVerificationPendingReview
                            : (isRejected
                                ? context.l10n.resubmitVerification
                                : context.l10n.proSubmitNicAction),
                        leadingIcon: isPending
                            ? Icons.hourglass_top_rounded
                            : (isRejected
                                ? Icons.refresh_rounded
                                : Icons.badge_outlined),
                        onPressed: isPending
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NicVerificationScreen(),
                                  ),
                                );
                              },
                      ),
                      if (isCustomerHistory) ...[
                        const SizedBox(height: 12),
                        AppOutlineButton(
                          label: context.l10n.backToCustomerDashboard,
                          icon: Icons.dashboard_outlined,
                          onPressed: () {
                            if (kDebugMode) {
                              debugPrint(
                                  '[navdbg] -> customer home from provider_approval_gate.dart');
                            }
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomeDiscoveryScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
