import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../constants/firestore_paths.dart';
import '../../../utils/l10n_extension.dart';
import '../../../app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/language_select_sheet.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../support/screens/help_support_screen.dart';
import '../../auth/screens/complete_profile_screen.dart';
import 'provider_dashboard_screen.dart';

// pending or rejected provider screen
class ProviderPendingScreen extends StatefulWidget {
  final bool isExistingCustomer;

  const ProviderPendingScreen({
    super.key,
    required this.isExistingCustomer,
  });

  @override
  State<ProviderPendingScreen> createState() => _ProviderPendingScreenState();
}

class _ProviderPendingScreenState extends State<ProviderPendingScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _techSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;

  Map<String, dynamic>? _techData;
  Map<String, dynamic>? _queueData;
  bool _navigatedToDashboard = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _techSub?.cancel();
    _queueSub?.cancel();
    super.dispose();
  }

  void _startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    _techSub = FirebaseFirestore.instance
        .collection(FirestorePaths.technicians)
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _techData = snap.data());
      _checkApproval();
    });

    _queueSub = FirebaseFirestore.instance
        .collection(FirestorePaths.verificationQueue)
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _queueData = snap.data());
      _checkApproval();
    });
  }

  void _checkApproval() {
    if (_navigatedToDashboard || !mounted) return;

    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final isTechApproved = _techData?['isVerified'] == true ||
        _techData?['nicVerified'] == true;
    final isQueueApproved = _queueData?['status'] == 'approved';

    if (isTechApproved || isQueueApproved || roleProvider.isApprovedProvider) {
      _navigatedToDashboard = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.providerApprovedCelebration),
            backgroundColor: AppColors.primary,
          ),
        );
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;

    final queueStatus = _queueData?['status'] as String?;
    final techStatus = _techData?['status'] as String?;
    final isRejected = queueStatus == 'rejected' ||
        queueStatus == 'resubmit' ||
        techStatus == 'rejected';

    final rejectionReason = (_queueData?['rejectionReason'] ??
        _queueData?['reason'] ??
        _techData?['rejectionReason'] ??
        _techData?['reason']) as String?;

    final submittedTs = (_queueData?['submittedAt'] as Timestamp?) ??
        (_techData?['createdAt'] as Timestamp?);
    final submittedDate = submittedTs?.toDate();

    final category = (_techData?['category'] ??
        _techData?['serviceCategory'] ??
        _queueData?['serviceCategory'] ??
        _queueData?['trade'] ??
        user?.serviceCategory ??
        '-') as String;

    final name = (_techData?['name'] ??
        _queueData?['providerName'] ??
        _queueData?['name'] ??
        user?.displayName ??
        '-') as String;

    return PopScope(
      canPop: widget.isExistingCustomer,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.isExistingCustomer) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  const SizedBox(height: 12),

                  // header icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isRejected
                            ? AppColors.error.withValues(alpha: 0.12)
                            : const Color(0xFFD6900F).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRejected
                            ? Icons.error_outline_rounded
                            : Icons.hourglass_top_rounded,
                        color: isRejected
                            ? AppColors.error
                            : const Color(0xFFD6900F),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isRejected
                        ? context.l10n.providerRejectedTitle
                        : context.l10n.providerPendingTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.themeInk,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    isRejected
                        ? context.l10n.providerRejectedSubtitle
                        : context.l10n.providerPendingSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.themeTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // rejection note
                  if (isRejected && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                    AppCard(
                      color: AppColors.error.withValues(alpha: 0.08),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.rejectionReasonLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rejectionReason,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: context.themeInk,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // application summary
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.submittedDetailsTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.themeInk,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDetailRow(
                          context,
                          Icons.person_outline_rounded,
                          context.l10n.applicantNameLabel,
                          name,
                        ),
                        Divider(
                          height: 20,
                          color: context.themeBorder.withValues(alpha: 0.5),
                        ),
                        _buildDetailRow(
                          context,
                          Icons.build_outlined,
                          context.l10n.serviceCategoryLabel,
                          category,
                        ),
                        Divider(
                          height: 20,
                          color: context.themeBorder.withValues(alpha: 0.5),
                        ),
                        _buildDetailRow(
                          context,
                          Icons.calendar_today_outlined,
                          context.l10n.submittedDateLabel,
                          _formatDate(submittedDate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // resubmit
                  if (isRejected) ...[
                    PrimaryButton(
                      label: context.l10n.fixAndResubmit,
                      leadingIcon: Icons.refresh_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompleteProfileScreen(
                              initialProfile: user,
                              targetRole: AppRole.provider,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // customer mode
                  if (widget.isExistingCustomer) ...[
                    PrimaryButton(
                      label: context.l10n.continueAsCustomer,
                      leadingIcon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const HomeDiscoveryScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // support
                  AppOutlineButton(
                    label: context.l10n.helpSupportTitle,
                    icon: Icons.help_outline_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // language
                  AppOutlineButton(
                    label: context.l10n.appLanguageLabel,
                    icon: Icons.language_rounded,
                    onPressed: () => LanguageSelectSheet.show(context),
                  ),
                  const SizedBox(height: 10),

                  // sign out
                  AppOutlineButton(
                    label: context.l10n.logout,
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      await roleProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.themeTextSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: context.themeTextSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeInk,
          ),
        ),
      ],
    );
  }
}
