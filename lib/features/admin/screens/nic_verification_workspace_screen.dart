import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../models/admin_models.dart';
import '../../../models/admin_user.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../utils/l10n_extension.dart';

class NicVerificationWorkspaceScreen extends StatefulWidget {
  const NicVerificationWorkspaceScreen({super.key});

  @override
  State<NicVerificationWorkspaceScreen> createState() =>
      _NicVerificationWorkspaceScreenState();
}

class _NicVerificationWorkspaceScreenState
    extends State<NicVerificationWorkspaceScreen> {
  int _selected = 0;
  bool _isProcessing = false;

  Future<void> _handleApprove(VerificationQueueItem item) async {
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
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUid,
        });
      }

      if (item.providerId.isNotEmpty) {
        final tDoc = FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(item.providerId);
        batch.update(tDoc, {
          'nicVerified': true,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} approved & activated on HelaService!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving verification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject(VerificationQueueItem item) async {
    setState(() => _isProcessing = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
      if (item.id.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.verificationQueue)
            .doc(item.id)
            .update({
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUid,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification for ${item.name} rejected.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting verification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRequestResubmission(VerificationQueueItem item) async {
    setState(() => _isProcessing = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
      if (item.id.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.verificationQueue)
            .doc(item.id)
            .update({
          'status': 'resubmit',
          'flagged': true,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUid,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Requested clearer photo from ${item.name}.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting resubmission: $e'),
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
        final items = docs
            .map((d) => VerificationQueueItem.fromMap(d.id, d.data()))
            .toList();

        items.sort((a, b) {
          if (a.submittedAt == null && b.submittedAt == null) return 0;
          if (a.submittedAt == null) return 1;
          if (b.submittedAt == null) return -1;
          return b.submittedAt!.compareTo(a.submittedAt!);
        });

        final pendingCount =
            items.where((i) => i.status == 'pending').length;
        final approvedCount =
            items.where((i) => i.status == 'approved').length;
        final resubmitCount =
            items.where((i) => i.flagged || i.status == 'resubmit').length;
        final rejectedCount =
            items.where((i) => i.status == 'rejected').length;

        if (_selected >= items.length && items.isNotEmpty) {
          _selected = items.length - 1;
        }

        final selectedItem = items.isNotEmpty ? items[_selected] : null;

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
                    fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: isMobile ? 14 : 18),

              if (isMobile)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _QueueStat(
                        label: context.l10n.statPendingReview,
                        value: '$pendingCount',
                        color: AppColors.secondaryContainer),
                    _QueueStat(
                        label: context.l10n.statApproved,
                        value: '$approvedCount',
                        color: AppColors.primary),
                    _QueueStat(
                        label: context.l10n.statNeedsResubmission,
                        value: '$resubmitCount',
                        color: AppColors.outline),
                    _QueueStat(
                        label: context.l10n.statFlaggedRejected,
                        value: '$rejectedCount',
                        color: AppColors.error),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                        child: _QueueStat(
                            label: context.l10n.statPendingReview,
                            value: '$pendingCount',
                            color: AppColors.secondaryContainer)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QueueStat(
                            label: context.l10n.statApproved,
                            value: '$approvedCount',
                            color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QueueStat(
                            label: context.l10n.statNeedsResubmission,
                            value: '$resubmitCount',
                            color: AppColors.outline)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QueueStat(
                            label: context.l10n.statFlaggedRejected,
                            value: '$rejectedCount',
                            color: AppColors.error)),
                  ],
                ),
              SizedBox(height: isMobile ? 16 : 20),

              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.task_alt,
                          size: 54, color: AppColors.primary),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.verificationQueueClear,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: context.themeTextPrimary),
                      ),
                    ],
                  ),
                )
              else if (isMobile) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.incomingVerificationStream,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13, color: context.themeTextPrimary),
                            ),
                          ),
                          Text('$pendingCount Pending',
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(context.l10n.selectArtisanAudit,
                          style: TextStyle(
                              fontSize: 10.5, color: context.themeTextSecondary)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final selected = i == _selected;
                            return InkWell(
                              onTap: () => setState(() => _selected = i),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 240,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : context.themeSurfaceLow,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : context.themeBorder,
                                    width: selected ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(children: [
                                      Icon(item.tradeIcon,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: context.themeTextPrimary),
                                        ),
                                      ),
                                      Text(item.timeAgo,
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: context.themeTextSecondary)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.trade} • ${item.location}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: context.themeTextSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.nicNumber,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: context.themeTextSecondary),
                                          ),
                                        ),
                                        _buildStatusBadge(item),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedItem != null)
                  _buildDetailCard(selectedItem, isMobile),
              ] else ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 340,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.themeSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.themeBorder),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Incoming Verification Stream',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: context.themeTextPrimary)),
                                  ),
                                  Text('$pendingCount Pending',
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('Sorted by Most Recent',
                                  style: TextStyle(
                                      fontSize: 10, color: context.themeTextSecondary)),
                              const SizedBox(height: 10),
                              ...List.generate(items.length, (i) {
                                final item = items[i];
                                final selected = i == _selected;
                                return InkWell(
                                  onTap: () => setState(() => _selected = i),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.12)
                                          : context.themeSurfaceLow,
                                      border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : context.themeBorder),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Icon(item.tradeIcon,
                                              size: 14,
                                              color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                              child: Text(item.name,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12.5,
                                                      color: context.themeTextPrimary))),
                                          Text(item.timeAgo,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: context.themeTextSecondary)),
                                        ]),
                                        Text(
                                            '${item.trade} • ${item.location}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context.themeTextSecondary)),
                                        Text(
                                            '${item.nicNumber} — ${item.docNote}',
                                            style: TextStyle(
                                                fontSize: 10.5,
                                                color: context.themeTextSecondary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.fileKey.isNotEmpty
                                                    ? 'B2 Uploaded'
                                                    : 'Standard Doc',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: context.themeTextSecondary),
                                              ),
                                            ),
                                            _buildStatusBadge(item),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (selectedItem != null)
                        Expanded(
                            child: _buildDetailCard(selectedItem, isMobile)),
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

  Widget _buildStatusBadge(VerificationQueueItem item) {
    if (item.status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Approved',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w700)),
      );
    }
    if (item.status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(context.l10n.rejectedStatus,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.error,
                fontWeight: FontWeight.w700)),
      );
    }
    if (item.flagged || item.status == 'resubmit') {
      return Text(context.l10n.reviewRequired,
          style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.error,
              fontWeight: FontWeight.w700));
    }
    return Text(
        item.hasComputedMatch ? '${item.matchPercent}% Match' : context.l10n.manualReview,
        style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.primary,
            fontWeight: FontWeight.w700));
  }

  Widget _buildDetailCard(VerificationQueueItem selectedItem, bool isMobile) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final canVerifyNic = roleProvider.hasAdminPermission(AdminPermission.verifyNic);
    final isApproved = selectedItem.status == 'approved';
    final isRejected = selectedItem.status == 'rejected';

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                selectedItem.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 15,
                    color: context.themeTextPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isApproved
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isRejected
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isApproved
                    ? context.l10n.activeAndVerified
                    : (isRejected ? context.l10n.rejectedStatus : context.l10n.pendingVerificationStatus),
                style: TextStyle(
                    fontSize: 10.5,
                    color: isRejected ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 6, children: [
            _InfoRow(
                icon: Icons.call,
                text: selectedItem.phone.isNotEmpty
                    ? selectedItem.phone
                    : context.l10n.notProvided),
            _InfoRow(
                icon: Icons.home,
                text: selectedItem.location.isNotEmpty
                    ? selectedItem.location
                    : 'Western Province, Sri Lanka'),
            _InfoRow(
                icon: Icons.translate,
                text: selectedItem.preferredLanguage.isNotEmpty
                    ? selectedItem.preferredLanguage
                    : context.l10n.notSpecified),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.verified_user,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${context.l10n.manualNicReview} • NIC: ${selectedItem.nicNumber}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ]),
          ),
          if (selectedItem.fileKey.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${context.l10n.cloudStoragePath}: ${selectedItem.fileKey}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.outline),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.document_scanner, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selectedItem.flagged
                    ? context.l10n.ocrAuditFlagged
                    : context.l10n.ocrAuditConcordant,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ]),
          Builder(
            builder: (context) {
              final ocrFields = [
                OcrField(
                  icon: Icons.badge,
                  field: context.l10n.ocrFullName,
                  extracted: selectedItem.name.toUpperCase(),
                  registry: selectedItem.name,
                  status: selectedItem.hasComputedMatch
                      ? '${selectedItem.matchPercent}%'
                      : context.l10n.manualReview,
                ),
                OcrField(
                  icon: Icons.credit_card,
                  field: context.l10n.ocrNicNumber,
                  extracted: selectedItem.nicNumber,
                  registry: selectedItem.nicNumber,
                  status: selectedItem.flagged ? 'Flagged' : 'Match',
                ),
                OcrField(
                  icon: Icons.home,
                  field: context.l10n.ocrLocation,
                  extracted: selectedItem.location,
                  registry: '${selectedItem.location} (Verified GN Division)',
                  status: 'Valid',
                ),
                OcrField(
                  icon: Icons.assignment_turned_in,
                  field: context.l10n.ocrTradeNote,
                  extracted: selectedItem.trade,
                  registry: selectedItem.docNote,
                  status: selectedItem.status.toUpperCase(),
                ),
              ];

              if (isMobile) {
                return Column(
                  children: ocrFields
                      .map((f) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: AppColors.surfaceLow,
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(f.icon, size: 13, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.field,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.outline,
                                              fontWeight: FontWeight.w600)),
                                      Text(f.extracted,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      Text('Registry: ${f.registry}',
                                          style: const TextStyle(
                                              fontSize: 9.5,
                                              color: AppColors.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 12, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(f.status,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                );
              }

              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(0.8)
                },
                children: [
                  TableRow(children: [
                    _TCell(context.l10n.ocrDataField, header: true),
                    _TCell(context.l10n.ocrExtracted, header: true),
                    _TCell(context.l10n.ocrRegistry, header: true),
                    _TCell(context.l10n.ocrStatus, header: true),
                  ]),
                  ...ocrFields.map((f) => TableRow(children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Icon(f.icon,
                                  size: 13, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Flexible(
                                  child: Text(f.field,
                                      style: const TextStyle(fontSize: 11)))
                            ])),
                        _TCell(f.extracted),
                        _TCell(f.registry),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            const Icon(Icons.check,
                                size: 13, color: AppColors.primary),
                            Text(f.status,
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.primary)),
                          ]),
                        ),
                      ])),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(children: [
            _NicDocImagePreview(
              providerId: selectedItem.providerId,
              docType: 'front',
              label: context.l10n.docNicFront,
              fallbackIcon: Icons.badge,
            ),
            const SizedBox(width: 8),
            _NicDocImagePreview(
              providerId: selectedItem.providerId,
              docType: 'back',
              label: context.l10n.docNicBack,
              fallbackIcon: Icons.qr_code_scanner,
            ),
            const SizedBox(width: 8),
            _NicDocImagePreview(
              providerId: selectedItem.providerId,
              docType: 'selfie',
              label: context.l10n.docLiveness,
              fallbackIcon: Icons.face,
            ),
          ]),
          const SizedBox(height: 18),
          if (!canVerifyNic)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Read-Only Mode: NIC Verification permission required to approve or reject artisan credentials.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isMobile)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing || isApproved)
                        ? null
                        : () => _handleApprove(selectedItem),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle, size: 16),
                    label: Text(isApproved
                        ? context.l10n.artisanActivated
                        : context.l10n.approveAndActivateArtisan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isProcessing || isRejected)
                            ? null
                            : () => _handleReject(selectedItem),
                        icon: const Icon(Icons.cancel,
                            size: 14, color: AppColors.error),
                        label: Text(
                            isRejected ? context.l10n.rejectedStatus : context.l10n.rejectAction,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleRequestResubmission(selectedItem),
                        icon: const Icon(Icons.replay, size: 14),
                        label: Text(context.l10n.requestClearerPhoto,
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_isProcessing || isRejected)
                      ? null
                      : () => _handleReject(selectedItem),
                  icon: const Icon(Icons.cancel,
                      size: 14, color: AppColors.error),
                  label: Text(isRejected ? context.l10n.rejectedStatus : context.l10n.rejectAction,
                      style: const TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleRequestResubmission(selectedItem),
                    icon: const Icon(Icons.replay, size: 14),
                    label: Text(context.l10n.requestClearerPhoto)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: (_isProcessing || isApproved)
                      ? null
                      : () => _handleApprove(selectedItem),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle, size: 16),
                  label: Text(isApproved
                      ? context.l10n.artisanActivated
                      : context.l10n.approveAndActivateArtisan),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _QueueStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5, color: context.themeTextSecondary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: context.themeTextSecondary),
      const SizedBox(width: 4),
      Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.themeTextPrimary))),
    ]);
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool header;
  const _TCell(this.text, {this.header = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: header ? 10.5 : 11,
          color: header ? context.themeTextSecondary : context.themeTextPrimary,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _NicDocImagePreview extends StatelessWidget {
  final String providerId;
  final String docType;
  final String label;
  final IconData fallbackIcon;

  const _NicDocImagePreview({
    required this.providerId,
    required this.docType,
    required this.label,
    required this.fallbackIcon,
  });

  void _showZoomDialog(BuildContext context, Uint8List bytes, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black87,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (providerId.isEmpty) {
      return _buildFallback(context, 'No ID');
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('nicImages')
          .doc(providerId)
          .collection('files')
          .doc(docType)
          .get(),
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

        final data = snapshot.data?.data();
        final rawBlob = data?['data'];
        Uint8List? bytes;
        if (rawBlob is Blob) {
          bytes = rawBlob.bytes;
        }

        if (bytes == null || bytes.isEmpty) {
          return _buildFallback(context, 'No image');
        }

        return Expanded(
          child: InkWell(
            onTap: () => _showZoomDialog(context, bytes!, label),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 68,
                      width: double.infinity,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(fallbackIcon,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Tap to zoom',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
      },
    );
  }

  Widget _buildFallback(BuildContext context, String tag) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 68,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(fallbackIcon, color: AppColors.onSurfaceVariant),
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
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

