import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as pv;
import '../../../constants/app_config.dart';
import '../../../constants/firestore_paths.dart';
import '../../../models/admin_models.dart';
import '../../../models/admin_user.dart';
import '../../../services/admin_log_service.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';
import '../../../utils/nic_decoder.dart';

enum _QueueFilter { pending, resubmit, rejected, approved, all }

class NicVerificationWorkspaceScreen extends StatefulWidget {
  const NicVerificationWorkspaceScreen({super.key});

  @override
  State<NicVerificationWorkspaceScreen> createState() =>
      _NicVerificationWorkspaceScreenState();
}

class _NicVerificationWorkspaceScreenState
    extends State<NicVerificationWorkspaceScreen> {
  String? _selectedId;
  _QueueFilter _filter = _QueueFilter.pending;
  final Set<int> _checklist = <int>{};
  bool _isProcessing = false;
  int _refreshCounter = 0;

  // approve photo only
  Future<void> _handleApproveDp(VerificationQueueItem item) async {
    setState(() => _isProcessing = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      if (item.id.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.verificationQueue)
              .doc(item.id),
          {'photoApproved': true},
          SetOptions(merge: true),
        );
      }
      if (item.providerId.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.technicians)
              .doc(item.providerId),
          {'photoStatus': 'approved'},
          SetOptions(merge: true),
        );
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.users)
              .doc(item.providerId),
          {'photoStatus': 'approved'},
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      await AdminLogService.instance.logAction(
        action: 'approve_profile_photo',
        targetType: 'technician_verification',
        targetId: item.providerId,
        details: 'Approved provider profile photo',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profilePhotoApproved),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorApprovingPhoto(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // approve nic only
  Future<void> _handleApproveNic(VerificationQueueItem item) async {
    setState(() => _isProcessing = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      if (item.id.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.verificationQueue)
              .doc(item.id),
          {'nicApproved': true},
          SetOptions(merge: true),
        );
      }
      if (item.providerId.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.technicians)
              .doc(item.providerId),
          {'nicVerified': true},
          SetOptions(merge: true),
        );
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.users)
              .doc(item.providerId),
          {'nicVerified': true},
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      await AdminLogService.instance.logAction(
        action: 'approve_nic_document',
        targetType: 'technician_verification',
        targetId: item.providerId,
        details: 'Approved provider NIC document',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nicVerified),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorApprovingNic(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // approve trade certificates
  Future<void> _handleApproveCerts(VerificationQueueItem item) async {
    setState(() => _isProcessing = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      if (item.id.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.verificationQueue)
              .doc(item.id),
          {'certsApproved': true},
          SetOptions(merge: true),
        );
      }
      if (item.providerId.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.technicians)
              .doc(item.providerId),
          {'certificationsStatus': 'approved', 'isVerified': true},
          SetOptions(merge: true),
        );
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestorePaths.users)
              .doc(item.providerId),
          {'certificationsStatus': 'approved'},
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      await AdminLogService.instance.logAction(
        action: 'approve_certifications',
        targetType: 'technician_verification',
        targetId: item.providerId,
        details: 'Approved trade certifications and licenses',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tradeCertificationsApproved),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorApprovingCertifications(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // full provider approval after 5 checklist points
  Future<void> _handleApprove(VerificationQueueItem item) async {
    if (_checklist.length < 5) return;
    setState(() => _isProcessing = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
      final batch = FirebaseFirestore.instance.batch();

      if (item.id.isNotEmpty) {
        final qDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.verificationQueue)
            .doc(item.id);
        batch.update(qDoc, {
          'status': 'approved',
          'photoApproved': true,
          'nicApproved': true,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUid,
        });
      }

      if (item.providerId.isNotEmpty) {
        final tDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(item.providerId);
        batch.set(tDoc, {
          'nicVerified': true,
          'isVerified': true,
          'status': 'active',
          'photoStatus': 'approved',
        }, SetOptions(merge: true));

        final uDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(item.providerId);
        batch.set(uDoc, {
          'role': 'provider',
          'isVerified': true,
          'photoStatus': 'approved',
        }, SetOptions(merge: true));

        // notify provider of approval
        final notifCol = FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(item.providerId)
            .collection('notifications');
        final lang = item.preferredLanguage.trim().toLowerCase();
        final notifTitle = lang == 'si'
            ? 'හැඳුනුම්පත් සත්‍යාපනය අනුමතයි'
            : (lang == 'ta'
                ? 'அடையாளச் சரிபார்ப்பு அங்கீகரிக்கப்பட்டது'
                : 'Identity Verification Approved');
        final notifBody = lang == 'si'
            ? 'ඔබගේ අනන්‍යතා සත්‍යාපනය අනුමත කරන ලදී. ඔබගේ පැතිකඩ දැන් සක්‍රීයයි.'
            : (lang == 'ta'
                ? 'உங்கள் அடையாளச் சரிபார்ப்பு அங்கீகரிக்கப்பட்டது. உங்கள் சுயவிவரம் இப்போது செயலில் உள்ளது.'
                : 'Your identity verification was approved. Your profile is now active.');
        batch.set(notifCol.doc(), {
          'title': notifTitle,
          'body': notifBody,
          'type': 'verification_approved',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await AdminLogService.instance.logAction(
        action: 'approve_verification',
        targetType: 'technician_verification',
        targetId: item.providerId,
        details: 'Approved provider identity after 5-point verification checklist',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nicDeskApprovedActivated(item.name)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nicDeskErrorApproving('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // open dialog for rejection or resubmission request
  Future<void> _openDecisionDialog(VerificationQueueItem item) async {
    final reasons = [
      context.l10n.reasonBlurryPhoto,
      context.l10n.reasonWrongSide,
      context.l10n.reasonNameMismatch,
      context.l10n.reasonNicMismatch,
      context.l10n.reasonFaceMismatch,
      context.l10n.reasonOther,
    ];

    String selectedReason = reasons.first;
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.l10n.rejectionReasonDialogTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.selectPresetReason,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.themeSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedReason,
                      items: reasons
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() => selectedReason = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLength: 300,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: context.l10n.optionalReviewerNote,
                    labelStyle: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                    filled: true,
                    fillColor: context.themeSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.themeBorder),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: context.themeTextSecondary),
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                Navigator.of(dlgCtx).pop();
                await _submitDecision(
                  item: item,
                  status: 'resubmit',
                  reason: selectedReason,
                  note: noteController.text.trim(),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD6900F)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                context.l10n.requestResubmission,
                style: const TextStyle(
                  color: Color(0xFFD6900F),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dlgCtx).pop();
                await _submitDecision(
                  item: item,
                  status: 'rejected',
                  reason: selectedReason,
                  note: noteController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                context.l10n.rejectApplication,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // write decision to firestore and send notification
  Future<void> _submitDecision({
    required VerificationQueueItem item,
    required String status,
    required String reason,
    required String note,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
      final batch = FirebaseFirestore.instance.batch();

      if (item.id.isNotEmpty) {
        final qDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.verificationQueue)
            .doc(item.id);
        batch.update(qDoc, {
          'status': status,
          'flagged': status == 'resubmit' || status == 'rejected',
          'rejectionReason': reason,
          'rejectionNote': note,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUid,
        });
      }

      if (item.providerId.isNotEmpty) {
        final tDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(item.providerId);
        batch.set(tDoc, {
          'rejectionReason': reason,
          'rejectionNote': note,
          if (status == 'rejected') 'status': 'rejected',
        }, SetOptions(merge: true));

        final notifTitle = status == 'resubmit'
            ? context.l10n.providerResubmitTitle
            : context.l10n.providerRejectedTitle;
        final notifBody = note.isNotEmpty ? '$reason: $note' : reason;

        final notifDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(item.providerId)
            .collection('notifications')
            .doc();
        batch.set(notifDoc, {
          'title': notifTitle,
          'body': notifBody,
          'type': status == 'resubmit'
              ? 'verification_resubmit'
              : 'verification_rejected',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await AdminLogService.instance.logAction(
        action: status == 'resubmit' ? 'request_resubmission' : 'reject_verification',
        targetType: 'technician_verification',
        targetId: item.providerId,
        details: 'Decision: $status. Reason: $reason. Note: $note',
      );

      if (mounted) {
        final msg = status == 'resubmit'
            ? context.l10n.nicDeskRequestedClearerPhoto(item.name)
            : context.l10n.nicDeskVerificationRejected(item.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'resubmit'
                ? const Color(0xFFD6900F)
                : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nicDeskErrorRejecting('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.verificationQueue)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final allItems = docs
            .map((d) => VerificationQueueItem.fromMap(d.id, d.data()))
            .toList();

        // sort fifo: oldest first
        allItems.sort((a, b) {
          if (a.submittedAt == null && b.submittedAt == null) return 0;
          if (a.submittedAt == null) return 1;
          if (b.submittedAt == null) return -1;
          return a.submittedAt!.compareTo(b.submittedAt!);
        });

        final pendingCount = allItems.where((i) => i.status == 'pending').length;
        final resubmitCount =
            allItems.where((i) => i.status == 'resubmit' || i.flagged).length;
        final rejectedCount = allItems.where((i) => i.status == 'rejected').length;
        final approvedCount = allItems.where((i) => i.status == 'approved').length;

        // filter items
        final filteredItems = allItems.where((item) {
          switch (_filter) {
            case _QueueFilter.pending:
              return item.status == 'pending';
            case _QueueFilter.resubmit:
              return item.status == 'resubmit' || (item.flagged && item.status != 'rejected');
            case _QueueFilter.rejected:
              return item.status == 'rejected';
            case _QueueFilter.approved:
              return item.status == 'approved';
            case _QueueFilter.all:
              return true;
          }
        }).toList();

        // preserve or set selected
        if (_selectedId == null ||
            !filteredItems.any((i) => i.id == _selectedId)) {
          if (filteredItems.isNotEmpty) {
            _selectedId = filteredItems.first.id;
          } else {
            _selectedId = null;
          }
        }

        final selectedItem = filteredItems.firstWhere(
          (i) => i.id == _selectedId,
          orElse: () => allItems.firstWhere(
            (i) => i.id == _selectedId,
            orElse: () => filteredItems.isNotEmpty ? filteredItems.first : allItems.firstOrNull ?? const VerificationQueueItem(name: '', trade: '', location: '', nicNumber: ''),
          ),
        );

        final hasSelection = selectedItem.id.isNotEmpty;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 16 : 24,
            isMobile ? 16 : 24,
            isMobile ? AppBottomNav.contentBottomPadding : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.nicVerificationDeskTitle,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              // filter chips with live counts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    label: '${context.l10n.filterPending} ($pendingCount)',
                    filter: _QueueFilter.pending,
                    color: const Color(0xFFD6900F),
                  ),
                  _buildFilterChip(
                    label: '${context.l10n.filterResubmitted} ($resubmitCount)',
                    filter: _QueueFilter.resubmit,
                    color: AppColors.outline,
                  ),
                  _buildFilterChip(
                    label: '${context.l10n.filterRejected} ($rejectedCount)',
                    filter: _QueueFilter.rejected,
                    color: AppColors.error,
                  ),
                  _buildFilterChip(
                    label: '${context.l10n.filterApproved} ($approvedCount)',
                    filter: _QueueFilter.approved,
                    color: AppColors.primary,
                  ),
                  _buildFilterChip(
                    label: '${context.l10n.filterAll} (${allItems.length})',
                    filter: _QueueFilter.all,
                    color: context.themeTextSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (allItems.isEmpty)
                _buildEmptyQueueCard()
              else if (filteredItems.isEmpty)
                _buildNoMatchingFilterCard()
              else if (isMobile) ...[
                // mobile queue list
                _buildQueueHorizontalList(filteredItems),
                const SizedBox(height: 16),
                if (hasSelection) _buildDetailCard(selectedItem, isMobile),
              ] else ...[
                // desktop layout: left queue list, right detail view
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 340,
                        child: _buildQueueVerticalList(filteredItems),
                      ),
                      const SizedBox(width: 16),
                      if (hasSelection)
                        Expanded(child: _buildDetailCard(selectedItem, isMobile)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _QueueFilter filter,
    required Color color,
  }) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() {
        _filter = filter;
        _checklist.clear();
      }),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : context.themeSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color : context.themeBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? color : context.themeTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQueueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt, size: 54, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            context.l10n.verificationQueueClear,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.themeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchingFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Center(
        child: Text(
          'No submissions found for selected filter.',
          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
        ),
      ),
    );
  }

  // mobile horizontal queue list
  Widget _buildQueueHorizontalList(List<VerificationQueueItem> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.incomingVerificationStream,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              Text(
                '${items.length} in queue',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                final selected = item.id == _selectedId;
                return InkWell(
                  onTap: () => setState(() {
                    _selectedId = item.id;
                    _checklist.clear();
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : context.themeSurfaceLow,
                      border: Border.all(
                        color: selected ? AppColors.primary : context.themeBorder,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildQueueCardContent(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // desktop vertical queue list
  Widget _buildQueueVerticalList(List<VerificationQueueItem> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.incomingVerificationStream,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              Text(
                '${items.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            'Sorted oldest first (FIFO)',
            style: TextStyle(fontSize: 10, color: context.themeTextSecondary),
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final selected = item.id == _selectedId;
            return InkWell(
              onTap: () => setState(() {
                _selectedId = item.id;
                _checklist.clear();
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : context.themeSurfaceLow,
                  border: Border.all(
                    color: selected ? AppColors.primary : context.themeBorder,
                    width: selected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildQueueCardContent(item),
              ),
            );
          }),
        ],
      ),
    );
  }

  // queue card inner content showing photo, name, category, district
  Widget _buildQueueCardContent(VerificationQueueItem item) {
    final displayName = item.name.isNotEmpty
        ? item.name
        : 'Provider #${item.providerId.length > 6 ? item.providerId.substring(0, 6) : item.providerId}';
    final tradeLabel = item.trade.isNotEmpty ? item.trade : 'General Service';
    final locLabel = item.location.isNotEmpty ? item.location : 'Sri Lanka';

    return Row(
      children: [
        // provider photo thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            color: context.themeSoft,
            child: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                ? Image.network(
                    item.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(item.tradeIcon, size: 20, color: AppColors.primary),
                  )
                : Icon(item.tradeIcon, size: 20, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    timeAgoL10n(context, item.submittedAt, fallback: item.timeAgo),
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$tradeLabel • $locLabel',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: context.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nicNumber.isNotEmpty ? item.nicNumber : 'NIC Pending',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                  _buildStatusBadge(item),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(VerificationQueueItem item) {
    if (item.status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: context.themeSuccessTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          context.l10n.statApproved,
          style: TextStyle(
            fontSize: 9.5,
            color: context.themeSuccess,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (item.status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: context.themeDangerTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          context.l10n.rejectedStatus,
          style: TextStyle(
            fontSize: 9.5,
            color: context.themeDanger,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (item.status == 'resubmit' || item.flagged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFD6900F).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Resubmit',
          style: TextStyle(
            fontSize: 9.5,
            color: Color(0xFFD6900F),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: context.themeAmberTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.statPendingReview,
        style: TextStyle(
          fontSize: 9.5,
          color: context.themeAmberText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // detail card for selected applicant
  Widget _buildDetailCard(VerificationQueueItem selectedItem, bool isMobile) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final canVerifyNic =
        roleProvider.hasAdminPermission(AdminPermission.verifyNic);
    final isApproved = selectedItem.status == 'approved';

    // load real kyc, user, and tech data
    return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(selectedItem.providerId)
            .collection('private')
            .doc('kyc')
            .get(),
        FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(selectedItem.providerId)
            .get(),
        FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(selectedItem.providerId)
            .get(),
      ]),
      builder: (context, snap) {
        final kycData = snap.data?[0].data();
        final userData = snap.data?[1].data();
        final techData = snap.data?[2].data();

        // read real nic from private/kyc (fallback to queue/tech)
        final realNic = (kycData?['nic'] as String?)?.trim().isNotEmpty == true
            ? (kycData!['nic'] as String).trim()
            : (selectedItem.nicNumber.isNotEmpty
                ? selectedItem.nicNumber
                : (techData?['nic'] as String? ?? ''));

        // read real phone and preferred language
        final realPhone = (userData?['phone'] as String?)?.isNotEmpty == true
            ? userData!['phone'] as String
            : (techData?['phone'] as String? ?? selectedItem.phone);
        final realLang = (userData?['preferredLanguage'] as String?)?.isNotEmpty == true
            ? userData!['preferredLanguage'] as String
            : selectedItem.preferredLanguage;

        final decodedNic = NicDecoder.decode(realNic);

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.themeBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row: name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedItem.name.isNotEmpty
                          ? selectedItem.name
                          : (userData?['name'] ?? 'Provider #${selectedItem.providerId.length > 6 ? selectedItem.providerId.substring(0, 6) : selectedItem.providerId}'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 16 : 18,
                        color: context.themeTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(selectedItem),
                ],
              ),
              const SizedBox(height: 10),

              // contact and meta info
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoRow(
                    icon: Icons.call,
                    text: realPhone.isNotEmpty ? realPhone : context.l10n.notProvided,
                  ),
                  _InfoRow(
                    icon: Icons.home,
                    text: selectedItem.location.isNotEmpty
                        ? selectedItem.location
                        : context.l10n.nicDeskDefaultLocation,
                  ),
                  _InfoRow(
                    icon: Icons.translate,
                    text: realLang.isNotEmpty ? realLang : context.l10n.notProvided,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // manual nic review bar with real nic
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.themeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${context.l10n.manualNicReview} • NIC: ${realNic.isNotEmpty ? realNic : context.l10n.notProvided}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // automated security & validity checks card (replaces fake ocr)
              _buildAutomaticChecksCard(
                realNic: realNic,
                decodedNic: decodedNic,
                phone: realPhone,
                item: selectedItem,
              ),
              const SizedBox(height: 16),

              // document comparison previews: profile photo, nic front, nic back
              _buildDocumentComparisonSection(
                item: selectedItem,
                isMobile: isMobile,
              ),
              const SizedBox(height: 10),

              // granular approval buttons
              Row(
                children: [
                  Expanded(
                    child: selectedItem.photoApproved
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.themeSuccessTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l10n.dpApproved,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: canVerifyNic
                                ? () => _handleApproveDp(selectedItem)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.approveDp,
                              style: const TextStyle(
                                  fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: selectedItem.nicApproved
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.themeSuccessTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l10n.nicVerified,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: canVerifyNic
                                ? () => _handleApproveNic(selectedItem)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.approveNicBoth,
                              style: const TextStyle(
                                  fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ],
              ),

              // trade certifications & licenses
              _buildCertificationsSection(
                selectedItem: selectedItem,
                canVerifyNic: canVerifyNic,
                techData: techData,
              ),
              const SizedBox(height: 18),

              // mandatory 5-point verification checklist
              _buildVerificationChecklist(canVerifyNic: canVerifyNic),
              const SizedBox(height: 18),

              // review & submission history from admin logs
              _buildReviewHistorySection(providerId: selectedItem.providerId),
              const SizedBox(height: 18),

              // action buttons (approve / reject / resubmit)
              if (!canVerifyNic)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.themeAmberTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.themeAmberText.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16, color: context.themeAmberText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.nicDeskReadOnlyMode,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeAmberText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildActionButtons(
                  item: selectedItem,
                  isApproved: isApproved,
                  isMobile: isMobile,
                ),
            ],
          ),
        );
      },
    );
  }

  // automated checks: nic format, decoding, age check, duplicate nic & phone checks
  Widget _buildAutomaticChecksCard({
    required String realNic,
    required DecodedNic decodedNic,
    required String phone,
    required VerificationQueueItem item,
  }) {
    return FutureBuilder<List<String>>(
      future: _runDuplicateChecks(item, phone),
      builder: (context, snap) {
        final duplicateWarnings = snap.data ?? [];
        final hasFormatError = !decodedNic.isValid;
        final hasUnder18 = decodedNic.isUnder18;
        final hasDuplicate = duplicateWarnings.isNotEmpty;
        final hasNoHash = item.nicHash == null || item.nicHash!.trim().isEmpty;

        final hasDanger = hasUnder18 || hasDuplicate;
        final hasWarning = hasFormatError || hasNoHash;

        final Color primaryColor = hasDanger
            ? context.themeDanger
            : (hasWarning ? const Color(0xFFD6900F) : context.themeSuccess);
        final Color tintColor = hasDanger
            ? context.themeDangerTint
            : (hasWarning ? context.themeAmberTint : context.themeSuccessTint);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasDanger
                        ? Icons.warning_amber_rounded
                        : (hasWarning
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_rounded),
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasDanger || hasFormatError
                          ? 'Automatic Checks: Attention Required'
                          : (hasNoHash
                              ? 'duplicate check not available yet'
                              : 'All Automatic Checks Passed'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  if (hasNoHash && !hasDanger && !hasFormatError)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6900F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'duplicate check not available yet',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD6900F),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // nic format & validity
              Row(
                children: [
                  Icon(
                    decodedNic.isValid ? Icons.check : Icons.close,
                    size: 14,
                    color: decodedNic.isValid ? context.themeSuccess : context.themeDanger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    decodedNic.isValid
                        ? '${context.l10n.nicFormatValid} (${decodedNic.isOldFormat ? "Old Format" : "New Format"})'
                        : '${context.l10n.nicFormatInvalid} (${decodedNic.errorMessage ?? ""})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: decodedNic.isValid ? context.themeTextPrimary : context.themeDanger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // decoded birth date and gender
              if (decodedNic.isValid) ...[
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      decodedNic.summary,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // age check warning if under 18
              if (hasUnder18) ...[
                Row(
                  children: [
                    Icon(Icons.person_off_rounded, size: 14, color: context.themeDanger),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.nicWarningUnder18(decodedNic.age ?? 0),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: context.themeDanger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // duplicate check warnings
              for (final warn in duplicateWarnings) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: context.themeDanger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warn,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.themeDanger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // duplicate check status when no duplicate warnings
              if (duplicateWarnings.isEmpty) ...[
                if (hasNoHash)
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Color(0xFFD6900F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.nicDuplicateCheckNotAvailable,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD6900F),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    context.l10n.noDuplicatesFound,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  // query duplicate nic hash & duplicate phone across database
  Future<List<String>> _runDuplicateChecks(
      VerificationQueueItem item, String phone) async {
    final l10n = context.l10n;
    final List<String> warnings = [];

    // duplicate nic check using nicHash
    if (item.nicHash != null && item.nicHash!.isNotEmpty) {
      try {
        final qSnap = await FirebaseFirestore.instance
            .collection(FirestorePaths.verificationQueue)
            .where('nicHash', isEqualTo: item.nicHash)
            .get();

        for (final doc in qSnap.docs) {
          if (doc.id == item.id) continue;
          final data = doc.data();
          final status = data['status'] as String? ?? 'pending';
          final name = data['providerName'] as String? ??
              data['name'] as String? ??
              'Provider';
          if (status == 'approved') {
            warnings.add(l10n.nicDuplicateNicApproved(name, doc.id));
          } else if (status == 'pending') {
            warnings.add(l10n.nicDuplicateNicPending(name, doc.id));
          }
        }
      } catch (_) {}
    }

    // duplicate phone check
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.isNotEmpty) {
      try {
        final techSnap = await FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .where('phone', isEqualTo: cleanPhone)
            .get();

        for (final doc in techSnap.docs) {
          if (doc.id == item.providerId) continue;
          final data = doc.data();
          final isVerified =
              data['isVerified'] == true || data['status'] == 'active';
          final name = data['name'] as String? ?? doc.id;
          if (isVerified) {
            warnings.add(l10n.nicDuplicatePhone(name));
          }
        }
      } catch (_) {}
    }

    return warnings;
  }

  // document comparison previews: profile photo, nic front, nic back
  Widget _buildDocumentComparisonSection({
    required VerificationQueueItem item,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.faceComparisonTitle,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.themeTextPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _refreshCounter++),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Refresh Images', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: const Size(0, 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _NicDocImagePreview(
              key: ValueKey('photo_${item.providerId}_$_refreshCounter'),
              providerId: item.providerId,
              directUrl: item.photoUrl,
              docType: 'photo',
              label: context.l10n.profilePhotoLabel,
              fallbackIcon: Icons.account_circle,
            ),
            const SizedBox(width: 8),
            _NicDocImagePreview(
              key: ValueKey('front_${item.providerId}_$_refreshCounter'),
              providerId: item.providerId,
              directUrl: item.nicFrontUrl,
              docType: 'front',
              label: context.l10n.nicFrontLabel,
              fallbackIcon: Icons.badge,
            ),
            const SizedBox(width: 8),
            _NicDocImagePreview(
              key: ValueKey('back_${item.providerId}_$_refreshCounter'),
              providerId: item.providerId,
              directUrl: item.nicBackUrl,
              docType: 'back',
              label: context.l10n.nicBackLabel,
              fallbackIcon: Icons.qr_code_scanner,
            ),
          ],
        ),
      ],
    );
  }

  // trade certifications section
  Widget _buildCertificationsSection({
    required VerificationQueueItem selectedItem,
    required bool canVerifyNic,
    required Map<String, dynamic>? techData,
  }) {
    final certsRaw =
        techData?['certificationUrls'] ?? selectedItem.certificationUrls;
    final certs = (certsRaw is List)
        ? certsRaw.map((e) => e.toString()).toList()
        : <String>[];
    if (certs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trade Certifications & Licenses (${certs.length})',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.themeTextPrimary,
              ),
            ),
            if (selectedItem.certsApproved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.themeSuccessTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.l10n.statusApproved,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (canVerifyNic)
              TextButton(
                onPressed: () => _handleApproveCerts(selectedItem),
                child: Text(
                  context.l10n.approveCerts,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: certs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, idx) {
              final certUrl = certs[idx];
              return GestureDetector(
                onTap: () => _showZoomDialog(
                    context, certUrl, 'Certificate #${idx + 1}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: context.themeSurfaceLow,
                    child: certUrl.startsWith('data:')
                        ? Image.memory(
                            base64Decode(certUrl.split(',').last),
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            certUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                size: 24),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // mandatory 5-point verification checklist
  Widget _buildVerificationChecklist({required bool canVerifyNic}) {
    final checklistItems = [
      context.l10n.chkPhotoClear,
      context.l10n.chkNameMatches,
      context.l10n.chkNicMatches,
      context.l10n.chkFaceMatches,
      context.l10n.chkCardNotEdited,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.playlist_add_check_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.approvalChecklistTitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              Text(
                '${_checklist.length}/5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _checklist.length == 5
                      ? context.themeSuccess
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < checklistItems.length; i++) ...[
            InkWell(
              onTap: canVerifyNic
                  ? () => setState(() {
                        if (_checklist.contains(i)) {
                          _checklist.remove(i);
                        } else {
                          _checklist.add(i);
                        }
                      })
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _checklist.contains(i),
                        onChanged: canVerifyNic
                            ? (val) => setState(() {
                                  if (val == true) {
                                    _checklist.add(i);
                                  } else {
                                    _checklist.remove(i);
                                  }
                                })
                            : null,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        checklistItems[i],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: _checklist.contains(i)
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // review & submission history from admin logs
  Widget _buildReviewHistorySection({required String providerId}) {
    if (providerId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('adminLogs')
          .where('targetId', isEqualTo: providerId)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.themeSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.themeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 16, color: context.themeTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.auditHistoryTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                Text(
                  'No previous reviews logged for this provider.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                )
              else
                Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final action = data['action'] as String? ?? 'action';
                    final details = data['details'] as String? ?? '';
                    final adminEmail = data['adminEmail'] as String? ?? 'Admin';
                    final ts = (data['timestamp'] as Timestamp?)?.toDate();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 6, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        action,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: context.themeTextPrimary,
                                        ),
                                      ),
                                    ),
                                    if (ts != null)
                                      Text(
                                        timeAgoL10n(context, ts, fallback: ''),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  '$adminEmail • $details',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // action buttons for approval, rejection, and resubmission
  Widget _buildActionButtons({
    required VerificationQueueItem item,
    required bool isApproved,
    required bool isMobile,
  }) {
    final canApprove = _checklist.length == 5 && !_isProcessing && !isApproved;

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: canApprove ? () => _handleApprove(item) : null,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                isApproved
                    ? context.l10n.artisanActivated
                    : context.l10n.approveAndActivateArtisan,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (!canApprove && !isApproved) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.allChecksRequired,
              style: TextStyle(
                fontSize: 10.5,
                color: context.themeTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _openDecisionDialog(item),
                  icon: Icon(Icons.cancel_outlined, size: 16, color: context.themeDanger),
                  label: Text(
                    context.l10n.rejectAction,
                    style: TextStyle(
                      color: context.themeDanger,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    side: BorderSide(color: context.themeDanger.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _openDecisionDialog(item),
                  icon: const Icon(Icons.replay, size: 16, color: Color(0xFFD6900F)),
                  label: Text(
                    context.l10n.requestResubmission,
                    style: const TextStyle(
                      color: Color(0xFFD6900F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    side: const BorderSide(color: Color(0xFFD6900F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _openDecisionDialog(item),
                icon: Icon(Icons.cancel_outlined, size: 16, color: context.themeDanger),
                label: Text(
                  context.l10n.rejectAction,
                  style: TextStyle(
                    color: context.themeDanger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 46),
                  side: BorderSide(color: context.themeDanger.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _openDecisionDialog(item),
                icon: const Icon(Icons.replay, size: 16, color: Color(0xFFD6900F)),
                label: Text(
                  context.l10n.requestResubmission,
                  style: const TextStyle(
                    color: Color(0xFFD6900F),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 46),
                  side: const BorderSide(color: Color(0xFFD6900F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canApprove ? () => _handleApprove(item) : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  isApproved
                      ? context.l10n.artisanActivated
                      : context.l10n.approveAndActivateArtisan,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  minimumSize: const Size(64, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!canApprove && !isApproved) ...[
          const SizedBox(height: 6),
          Text(
            context.l10n.allChecksRequired,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10.5,
              color: context.themeTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.themeTextSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.themeTextPrimary),
          ),
        ),
      ],
    );
  }
}

// full-screen viewer with pinch-to-zoom and 90° rotation
void _showZoomDialog(BuildContext context, String imageUrl, String title) {
  showDialog(
    context: context,
    builder: (ctx) => _ZoomableDocDialog(imageUrl: imageUrl, title: title),
  );
}

class _ZoomableDocDialog extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _ZoomableDocDialog({required this.imageUrl, required this.title});

  @override
  State<_ZoomableDocDialog> createState() => _ZoomableDocDialogState();
}

class _ZoomableDocDialogState extends State<_ZoomableDocDialog> {
  int _quarterTurns = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black87,
              child: Column(
                children: [
                  // header with title and rotate button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black54,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
                          icon: const Icon(Icons.rotate_90_degrees_cw, color: Colors.white, size: 16),
                          label: Text(
                            context.l10n.rotatePhoto,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5.0,
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: _quarterTurns,
                          child: widget.imageUrl.startsWith('data:')
                              ? Image.memory(
                                  base64Decode(widget.imageUrl.split(',').last),
                                  fit: BoxFit.contain,
                                )
                              : Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (_, child, prog) => prog == null
                                      ? child
                                      : const Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary),
                                        ),
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _NicDocImagePreview extends StatelessWidget {
  final String providerId;
  final String docType;
  final String label;
  final IconData fallbackIcon;
  final String? directUrl;

  const _NicDocImagePreview({
    super.key,
    required this.providerId,
    required this.docType,
    required this.label,
    required this.fallbackIcon,
    this.directUrl,
  });

  // fetch secure presigned url or direct image
  Future<String?> _resolveImageUrl() async {
    if (directUrl != null && directUrl!.isNotEmpty) {
      if (directUrl!.startsWith('http') || directUrl!.startsWith('data:')) {
        return directUrl;
      }
    }

    if (docType == 'photo') {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(providerId)
            .get();
        final photo = doc.data()?['photoUrl'] as String?;
        if (photo != null && photo.isNotEmpty) return photo;

        final uDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(providerId)
            .get();
        return uDoc.data()?['photoUrl'] as String?;
      } catch (_) {}
    }

    // request 5 minute presigned url from backend
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
        final uri = Uri.parse('$cleanBase/nic-url');

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-helaservice-key': AppConfig.apiSecretKey,
          },
          body: jsonEncode({
            'providerId': providerId,
            'side': docType,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final presignedUrl = data['url'] as String?;
          if (presignedUrl != null && presignedUrl.isNotEmpty) {
            return presignedUrl;
          }
        }
      }
    } catch (_) {}

    // fallback to technicians doc
    try {
      final techDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(providerId)
          .get();
      final data = techDoc.data();
      if (docType == 'front') return data?['nicFrontUrl'] as String?;
      if (docType == 'back') return data?['nicBackUrl'] as String?;
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (providerId.isEmpty && (directUrl == null || directUrl!.isEmpty)) {
      return _buildFallback(context, context.l10n.nicDeskNoId);
    }

    return FutureBuilder<String?>(
      future: _resolveImageUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Expanded(
            child: Container(
              height: 110,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final resolvedUrl = snapshot.data;
        if (resolvedUrl == null || resolvedUrl.isEmpty) {
          return _buildFallback(context, context.l10n.nicDeskNoImage);
        }

        return _buildImageCard(context, resolvedUrl);
      },
    );
  }

  Widget _buildImageCard(BuildContext context, String url) {
    return Expanded(
      child: InkWell(
        onTap: () => _showZoomDialog(context, url, label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.themeSurfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: url.startsWith('data:')
                      ? Image.memory(
                          base64Decode(url.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(fallbackIcon, color: context.themeTextSecondary),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(fallbackIcon, color: context.themeTextSecondary),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              Text(
                context.l10n.nicDeskTapToZoom,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, String tag) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.themeSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(fallbackIcon, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            Text(
              tag,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: context.themeTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
