import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/firestore_paths.dart';
import '../../../services/storage_service.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import 'certificate_upload_section.dart';

class CertificateManagementSheet extends StatefulWidget {
  final String providerId;

  const CertificateManagementSheet({super.key, required this.providerId});

  static Future<void> show(BuildContext context, String providerId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CertificateManagementSheet(providerId: providerId),
    );
  }

  @override
  State<CertificateManagementSheet> createState() =>
      _CertificateManagementSheetState();
}

class _CertificateManagementSheetState
    extends State<CertificateManagementSheet> {
  final List<PickedCertificateItem> _newItems = [];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final item in _newItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_newItems.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final certsCol = FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(widget.providerId)
          .collection('certificates');

      for (final item in _newItems) {
        String? certKey = item.uploadedKey;
        if (certKey == null) {
          certKey = await StorageService.instance.uploadBytes(
            item.bytes,
            filename: item.name,
            purpose: 'cert',
          );
          item.uploadedKey = certKey;
        }

        if (item.savedDocId == null) {
          final rawTitle = item.titleController.text.trim();
          final title =
              rawTitle.length > 80 ? rawTitle.substring(0, 80) : rawTitle;
          final docRef = certsCol.doc();
          await docRef.set({
            'key': certKey,
            'title': title,
            'type': item.isPdf ? 'pdf' : 'image',
            'status': 'pending',
            'uploadedAt': FieldValue.serverTimestamp(),
          });
          item.savedDocId = docRef.id;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.certSubmittedSuccess),
          backgroundColor: AppColors.primary,
        ),
      );

      setState(() {
        _newItems.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePendingCert(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(widget.providerId)
          .collection('certificates')
          .doc(docId)
          .delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = context.isDark;

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: media.viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.certApprovedSectionTitle,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // stream existing certificates
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection(FirestorePaths.technicians)
                          .doc(widget.providerId)
                          .collection('certificates')
                          .orderBy('uploadedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.certApprovedSectionTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final doc in docs) ...[
                              _buildExistingCertCard(doc, isDark),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 14),
                          ],
                        );
                      },
                    ),

                    // upload section
                    CertificateUploadSection(
                      items: _newItems,
                      onChanged: (updated) {
                        setState(() {
                          _newItems
                            ..clear()
                            ..addAll(updated);
                        });
                      },
                    ),

                    if (_newItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: context.l10n.certSaveButton,
                        loading: _isSaving,
                        onPressed: _handleSave,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingCertCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isDark,
  ) {
    final data = doc.data();
    final title = (data['title'] as String?)?.trim();
    final displayTitle = (title != null && title.isNotEmpty)
        ? title
        : context.l10n.certDefaultTitle;
    final status = (data['status'] as String?) ?? 'pending';
    final rejectReason = data['rejectReason'] as String?;
    final isPdf = data['type'] == 'pdf';

    Color statusColor = const Color(0xFFD6900F);
    Color statusBg = const Color(0xFFD6900F).withValues(alpha: 0.12);
    String statusLabel = context.l10n.statusPending;

    if (status == 'approved') {
      statusColor = AppColors.success;
      statusBg = context.themeSuccessTint;
      statusLabel = context.l10n.statusApproved;
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusBg = AppColors.error.withValues(alpha: 0.12);
      statusLabel = context.l10n.rejectedStatus;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: isPdf ? const Color(0xFFEF4444) : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              if (status == 'pending') ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _deletePendingCert(doc.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (status == 'rejected' &&
              rejectReason != null &&
              rejectReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rejectReason,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
