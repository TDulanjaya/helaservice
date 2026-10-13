import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/complaint.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/ticket_error_l10n.dart';
import 'package:provider/provider.dart';

class ReportProblemDialog extends StatefulWidget {
  final String bookingId;
  final String otherPartyId;
  final String otherPartyRole; // 'provider' | 'customer'
  final String otherPartyName;

  const ReportProblemDialog({
    super.key,
    required this.bookingId,
    required this.otherPartyId,
    required this.otherPartyRole,
    required this.otherPartyName,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    String? otherPartyId,
    String? otherPartyRole,
    String? otherPartyName,
    String? reportedUid,
    String? reportedRole,
    String? reportedName,
  }) {
    final finalId = otherPartyId ?? reportedUid ?? '';
    final finalRole = otherPartyRole ?? reportedRole ?? 'provider';
    final finalName = otherPartyName ?? reportedName ?? '';
    return showDialog(
      context: context,
      builder: (_) => ReportProblemDialog(
        bookingId: bookingId,
        otherPartyId: finalId,
        otherPartyRole: finalRole,
        otherPartyName: finalName,
      ),
    );
  }

  @override
  State<ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<ReportProblemDialog> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final List<PickedAttachment> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.themeSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.report_problem_outlined, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.reportAProblem,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking: ${widget.bookingId}',
              style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
            ),
            if (widget.otherPartyName.isNotEmpty)
              Text(
                'Party: ${widget.otherPartyName} (${widget.otherPartyRole})',
                style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: context.l10n.ticketSubject,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: context.l10n.ticketDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(_photos[i].bytes, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_photos.length < 3)
              OutlinedButton.icon(
                onPressed: () async {
                  final img = await _picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    final bytes = await img.readAsBytes();
                    setState(() => _photos.add(PickedAttachment(file: img, bytes: bytes)));
                  }
                },
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: Text(context.l10n.ticketAttachPhoto),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting
              ? null
              : () async {
                  final subj = _subjectController.text.trim();
                  final desc = _descriptionController.text.trim();
                  if (subj.isEmpty || desc.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  final successMsg = context.l10n.ticketCreatedSuccess;
                  final photoUploadFailedMsg = context.l10n.ticketPhotoUploadFailed;
                  final nav = Navigator.of(context);

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final roleProvider = Provider.of<RoleProvider>(context, listen: false);
                  final profile = roleProvider.currentUser ?? AuthService().currentUser;
                  final myRole = (profile?.role == AppRole.provider)
                      ? 'provider'
                      : ((profile?.role == AppRole.customer)
                          ? 'customer'
                          : (widget.otherPartyRole == 'provider' ? 'customer' : 'provider'));
                  final myName = (profile?.displayName.trim().isNotEmpty == true)
                      ? profile!.displayName.trim()
                      : ((user.displayName != null && user.displayName!.trim().isNotEmpty)
                          ? user.displayName!.trim()
                          : (user.email ?? ''));

                  setState(() => _isSubmitting = true);
                  final photoUrls = <String>[];
                  final storage = StorageService();
                  try {
                    for (final p in _photos) {
                      final url = await storage.uploadPickedAttachment(p, purpose: 'job_photo');
                      photoUrls.add(url);
                    }
                  } catch (e) {
                    debugPrint('[ReportProblemDialog] Photo upload failed: $e');
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(photoUploadFailedMsg),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    final ticket = Complaint(
                      type: 'booking_problem',
                      reporterUid: user.uid,
                      reporterRole: myRole,
                      reporterName: myName,
                      reportedUid: widget.otherPartyId,
                      reportedRole: widget.otherPartyRole,
                      reportedName: widget.otherPartyName,
                      bookingId: widget.bookingId,
                      subject: subj,
                      description: desc,
                      photos: photoUrls,
                      status: 'open',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      lastMessageAt: DateTime.now(),
                    );

                    await ComplaintRepository().submitComplaint(ticket);
                    if (context.mounted) {
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(successMsg),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('[ReportProblemDialog] submit error: $e');
                    if (context.mounted) {
                      setState(() => _isSubmitting = false);
                      messenger.showSnackBar(
                        SnackBar(content: Text(ticketErrorMessage(context, e)), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.l10n.ticketSend),
        ),
      ],
    );
  }
}
