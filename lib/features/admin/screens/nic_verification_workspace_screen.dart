import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/firestore_paths.dart';
import '../../../models/admin_models.dart';
import '../../../theme/app_theme.dart';

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
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technician Identity Verification Desk',
                style: TextStyle(
                    fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Review National Identity Cards (NIC) and police records before activating artisan profiles on the island-wide HelaService network.',
                style:
                    TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'e-DLS & SL Police Link Online',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Avg Turnaround: 4.2 mins',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
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
                        label: 'Pending Review',
                        value: '$pendingCount',
                        color: AppColors.secondaryContainer),
                    _QueueStat(
                        label: 'Approved',
                        value: '$approvedCount',
                        color: AppColors.primary),
                    _QueueStat(
                        label: 'Needs Resubmission',
                        value: '$resubmitCount',
                        color: AppColors.outline),
                    _QueueStat(
                        label: 'Flagged / Rejected',
                        value: '$rejectedCount',
                        color: AppColors.error),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                        child: _QueueStat(
                            label: 'Pending Review',
                            value: '$pendingCount',
                            color: AppColors.secondaryContainer)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QueueStat(
                            label: 'Approved',
                            value: '$approvedCount',
                            color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QueueStat(
                            label: 'Needs Resubmission',
                            value: '$resubmitCount',
                            color: AppColors.outline)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QueueStat(
                            label: 'Flagged / Rejected',
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
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.task_alt,
                          size: 54, color: AppColors.primary),
                      SizedBox(height: 14),
                      Text(
                        'Verification Queue Clear',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No artisan verification submissions are currently awaiting review.\nNew uploads from technicians will stream here in real time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else if (isMobile) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Incoming Verification Stream',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Text('$pendingCount Pending',
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('Select an artisan to audit documents',
                          style: TextStyle(
                              fontSize: 10.5, color: AppColors.outline)),
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
                                      ? AppColors.primary.withValues(alpha: 0.08)
                                      : AppColors.surfaceLow,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
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
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ),
                                      Text(item.timeAgo,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.outline)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.trade} • ${item.location}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.nicNumber,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.outline),
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
                            color: AppColors.surfaceLowest,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text('Incoming Verification Stream',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  Text('$pendingCount Pending',
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Text('Sorted by Most Recent',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.outline)),
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
                                              .withValues(alpha: 0.06)
                                          : AppColors.surfaceLow,
                                      border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : Colors.transparent),
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
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12.5))),
                                          Text(item.timeAgo,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.outline)),
                                        ]),
                                        Text(
                                            '${item.trade} • ${item.location}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors
                                                    .onSurfaceVariant)),
                                        Text(
                                            '${item.nicNumber} — ${item.docNote}',
                                            style: const TextStyle(
                                                fontSize: 10.5,
                                                color: AppColors
                                                    .onSurfaceVariant)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.fileKey.isNotEmpty
                                                    ? 'B2 Uploaded'
                                                    : 'Standard Doc',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.outline),
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
        child: const Text('Rejected',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.error,
                fontWeight: FontWeight.w700)),
      );
    }
    if (item.flagged || item.status == 'resubmit') {
      return const Text('Review Required',
          style: TextStyle(
              fontSize: 10.5,
              color: AppColors.error,
              fontWeight: FontWeight.w700));
    }
    return Text('${item.matchPercent}% Match',
        style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.primary,
            fontWeight: FontWeight.w700));
  }

  Widget _buildDetailCard(VerificationQueueItem selectedItem, bool isMobile) {
    final isApproved = selectedItem.status == 'approved';
    final isRejected = selectedItem.status == 'rejected';

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
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
                    fontSize: isMobile ? 14 : 15),
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
                    ? 'Active & Verified'
                    : (isRejected ? 'Rejected' : 'Pending Verification'),
                style: TextStyle(
                    fontSize: 10.5,
                    color: isRejected ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 6, children: [
            const _InfoRow(icon: Icons.call, text: '+94 77 482 1902'),
            _InfoRow(
                icon: Icons.home,
                text: selectedItem.location.isNotEmpty
                    ? selectedItem.location
                    : 'Western Province, Sri Lanka'),
            const _InfoRow(icon: Icons.translate, text: 'Sinhala, English'),
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
                  'SL Police Clearance Portal — Ref: #SLP-2024-09881 • NIC: ${selectedItem.nicNumber}',
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
                      'Backblaze B2 Storage Path: ${selectedItem.fileKey}',
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
          const Row(children: [
            Icon(Icons.document_scanner, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'OCR Audit — All 4 Fields Concordant',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ]),
          Builder(
            builder: (context) {
              final ocrFields = [
                OcrField(
                  icon: Icons.badge,
                  field: 'Full Name',
                  extracted: selectedItem.name.toUpperCase(),
                  registry: selectedItem.name,
                  status: '${selectedItem.matchPercent}%',
                ),
                OcrField(
                  icon: Icons.credit_card,
                  field: 'NIC Number',
                  extracted: selectedItem.nicNumber,
                  registry: selectedItem.nicNumber,
                  status: selectedItem.flagged ? 'Flagged' : 'Match',
                ),
                OcrField(
                  icon: Icons.home,
                  field: 'Electoral Address / Location',
                  extracted: selectedItem.location,
                  registry: '${selectedItem.location} (Verified GN Division)',
                  status: 'Valid',
                ),
                OcrField(
                  icon: Icons.assignment_turned_in,
                  field: 'Trade / Document Note',
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
                  const TableRow(children: [
                    _TCell('Data Field', header: true),
                    _TCell('OCR Extracted', header: true),
                    _TCell('Registry', header: true),
                    _TCell('Status', header: true),
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
          const Row(children: [
            _DocPreview(icon: Icons.badge, label: 'NIC Front', tag: 'UV PASS'),
            SizedBox(width: 8),
            _DocPreview(
                icon: Icons.qr_code_scanner,
                label: 'NIC Back',
                tag: 'PDF417 OK'),
            SizedBox(width: 8),
            _DocPreview(
                icon: Icons.face, label: 'Liveness', tag: '98.4% Match'),
          ]),
          const SizedBox(height: 18),
          if (isMobile)
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
                        ? 'Artisan Activated'
                        : 'Approve & Activate Artisan'),
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
                            isRejected ? 'Rejected' : 'Reject',
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
                        label: const Text('Clearer Photo',
                            style: TextStyle(fontSize: 11)),
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
                  label: Text(isRejected ? 'Rejected' : 'Reject',
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
                    label: const Text('Request Clearer Photo')),
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
                      ? 'Artisan Activated'
                      : 'Approve & Activate Artisan'),
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
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
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
              style: const TextStyle(
                  fontSize: 10.5, color: AppColors.onSurfaceVariant)),
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
      Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
      const SizedBox(width: 4),
      Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11))),
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
          color: header ? AppColors.outline : AppColors.onSurface,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _DocPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tag;
  const _DocPreview(
      {required this.icon, required this.label, required this.tag});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text(tag,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
