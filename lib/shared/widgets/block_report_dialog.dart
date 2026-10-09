import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/complaint.dart';
import '../../repositories/block_repository.dart';
import '../../repositories/complaint_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import 'primary_button.dart';

class BlockReportHelper {
  BlockReportHelper._();

  // show confirmation dialog to block a user
  static Future<void> showBlockConfirmation(
    BuildContext context, {
    required String targetUid,
    required String targetName,
    VoidCallback? onBlocked,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
          dlgCtx.l10n.blockUserAction,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          dlgCtx.l10n.blockUserConfirm,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(dlgCtx.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(dlgCtx.l10n.blockUserAction),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await BlockRepository().blockUser(
        blockedUid: targetUid,
        name: targetName,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.userBlockedSuccess),
            backgroundColor: AppColors.error,
          ),
        );
        onBlocked?.call();
      }
    }
  }

  // show bottom sheet modal to report a user or provider
  static Future<void> showReportSheet(
    BuildContext context, {
    required String targetUid,
    required String targetName,
    required String targetRole,
    String? bookingId,
    String? tradeCategory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportUserSheet(
        targetUid: targetUid,
        targetName: targetName,
        targetRole: targetRole,
        bookingId: bookingId,
        tradeCategory: tradeCategory,
      ),
    );
  }
}

class _ReportUserSheet extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String targetRole;
  final String? bookingId;
  final String? tradeCategory;

  const _ReportUserSheet({
    required this.targetUid,
    required this.targetName,
    required this.targetRole,
    this.bookingId,
    this.tradeCategory,
  });

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  final TextEditingController _descController = TextEditingController();
  String _selectedReason = 'behavior';
  bool _alsoBlock = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  String _reasonLabel(String key, BuildContext context) {
    switch (key) {
      case 'behavior':
        return context.l10n.reportReasonHarassment;
      case 'spam':
        return context.l10n.reportReasonSpam;
      case 'fraud':
        return context.l10n.reportReasonFraud;
      case 'noshow':
        return context.l10n.reportReasonNoShow;
      case 'safety':
        return context.l10n.reportReasonSafety;
      default:
        return context.l10n.reportReasonOther;
    }
  }

  Future<void> _handleSubmit() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reportDetailsHint)),
      );
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentName = currentUser?.displayName ?? 'User';
    final currentPhone = currentUser?.phoneNumber ?? '';

    setState(() => _isSubmitting = true);
    try {
      final complaint = Complaint(
        customerId: currentUid,
        customerName: currentName,
        customerPhone: currentPhone,
        providerId: widget.targetUid,
        providerName: widget.targetName,
        providerTrade: widget.tradeCategory ?? 'General',
        bookingId: widget.bookingId,
        reason: _reasonLabel(_selectedReason, context),
        description: desc,
        reporterRole: widget.targetRole == 'provider' ? 'customer' : 'provider',
        accusedRole: widget.targetRole,
        createdAt: DateTime.now(),
      );

      await ComplaintRepository().submitComplaint(complaint);

      if (_alsoBlock) {
        await BlockRepository().blockUser(
          blockedUid: widget.targetUid,
          name: widget.targetName,
          reason: desc,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.reportSubmittedSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = ['behavior', 'spam', 'fraud', 'noshow', 'safety', 'other'];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_problem_rounded,
                        color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${context.l10n.reportReasonLabel}: ${widget.targetName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.reportReasonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ...reasons.map((key) {
                final isSelected = _selectedReason == key;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = key),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : context.themeTextSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _reasonLabel(key, context),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? context.themeInk
                                  : context.themeTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                context.l10n.portfolioItemDesc,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.l10n.reportDetailsHint,
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _alsoBlock,
                onChanged: (val) => setState(() => _alsoBlock = val ?? false),
                title: Text(
                  context.l10n.reportAlsoBlock,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.error,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: context.l10n.reportReasonLabel,
                loading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
