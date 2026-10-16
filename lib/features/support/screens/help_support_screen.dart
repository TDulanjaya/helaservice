import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_config.dart';
import '../../../models/complaint.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';
import '../../../utils/ticket_error_l10n.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'support_ticket_detail_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _complaintRepo = ComplaintRepository();
  final _picker = ImagePicker();

  void _showNewTicketSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'help';
    final List<PickedAttachment> selectedPhotos = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.contactSupport,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.ticketReplyPrompt,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.ticketCategory,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(context.l10n.typeHelp),
                          selected: selectedType == 'help',
                          onSelected: (s) =>
                              setSheetState(() => selectedType = 'help'),
                        ),
                        ChoiceChip(
                          label: Text(context.l10n.typeAccount),
                          selected: selectedType == 'account',
                          onSelected: (s) =>
                              setSheetState(() => selectedType = 'account'),
                        ),
                        ChoiceChip(
                          label: Text(context.l10n.typeAppProblem),
                          selected: selectedType == 'app_problem',
                          onSelected: (s) =>
                              setSheetState(() => selectedType = 'app_problem'),
                        ),
                        ChoiceChip(
                          label: Text(context.l10n.typeFeedback),
                          selected: selectedType == 'feedback',
                          onSelected: (s) =>
                              setSheetState(() => selectedType = 'feedback'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: subjectController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: context.l10n.ticketSubject,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: context.l10n.ticketDescription,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (selectedPhotos.isNotEmpty) ...[
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedPhotos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  selectedPhotos[i].bytes,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setSheetState(
                                      () => selectedPhotos.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (selectedPhotos.length < 3)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final img = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setSheetState(() => selectedPhotos.add(
                                PickedAttachment(file: img, bytes: bytes)));
                          }
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: Text(context.l10n.ticketAttachPhoto),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final subj = subjectController.text.trim();
                                final desc = descriptionController.text.trim();
                                if (subj.isEmpty || desc.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(context
                                            .l10n.pleaseFillRequiredFields)),
                                  );
                                  return;
                                }

                                final roleProvider = Provider.of<RoleProvider>(
                                    context,
                                    listen: false);
                                final profile = roleProvider.currentUser ??
                                    AuthService().currentUser;
                                final String reporterRole =
                                    (profile?.role == AppRole.provider)
                                        ? 'provider'
                                        : 'customer';
                                final String reporterName = (profile
                                            ?.displayName
                                            .trim()
                                            .isNotEmpty ==
                                        true)
                                    ? profile!.displayName.trim()
                                    : ((user.displayName != null &&
                                            user.displayName!.trim().isNotEmpty)
                                        ? user.displayName!.trim()
                                        : (user.email ?? ''));

                                setSheetState(() => isSubmitting = true);
                                final photoUrls = <String>[];
                                final storageService = StorageService();
                                try {
                                  for (final p in selectedPhotos) {
                                    final uploadedUrl = await storageService
                                        .uploadPickedAttachment(
                                      p,
                                      purpose: 'job_photo',
                                    );
                                    photoUrls.add(uploadedUrl);
                                  }
                                } catch (e) {
                                  debugPrint(
                                      '[HelpSupportScreen] Photo upload failed: $e');
                                  if (context.mounted) {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context
                                            .l10n.ticketPhotoUploadFailed),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                try {
                                  final ticket = Complaint(
                                    type: selectedType,
                                    reporterUid: user.uid,
                                    reporterRole: reporterRole,
                                    reporterName: reporterName,
                                    subject: subj,
                                    description: desc,
                                    photos: photoUrls,
                                    status: 'open',
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    lastMessageAt: DateTime.now(),
                                  );

                                  await _complaintRepo.submitComplaint(ticket);
                                  if (context.mounted) {
                                    Navigator.pop(bCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            context.l10n.ticketCreatedSuccess),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint(
                                      '[HelpSupportScreen] Failed to submit ticket: $e');
                                  if (context.mounted) {
                                    setSheetState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            ticketErrorMessage(context, e)),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(context.l10n.ticketSend),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFD6900F);
      case 'in_progress':
        return AppColors.primary;
      case 'waiting_user':
        return const Color(0xFF8E24AA);
      case 'resolved':
        return const Color(0xFF2E7D32);
      case 'closed':
        return const Color(0xFF757575);
      default:
        return const Color(0xFFD6900F);
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    switch (status) {
      case 'open':
        return context.l10n.ticketStatusOpen;
      case 'in_progress':
        return context.l10n.ticketStatusInProgress;
      case 'waiting_user':
        return context.l10n.ticketStatusWaitingUser;
      case 'resolved':
        return context.l10n.ticketStatusResolved;
      case 'closed':
        return context.l10n.ticketStatusClosed;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    String rcPhone = '';
    String rcEmail = '';
    try {
      rcPhone = FirebaseRemoteConfig.instance.getString('support_phone').trim();
      rcEmail = FirebaseRemoteConfig.instance.getString('support_email').trim();
    } catch (_) {
      rcPhone = '';
      rcEmail = '';
    }
    final supportPhone = rcPhone.isNotEmpty ? rcPhone : AppConfig.supportPhone;
    final supportEmail = rcEmail.isNotEmpty ? rcEmail : AppConfig.supportEmail;

    return Scaffold(
      backgroundColor: context.themeSurface,
      appBar: AppBar(
        title: Text(context.l10n.helpAndSupport),
        backgroundColor: context.themeSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.helpAndSupport,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.ticketReplyPrompt,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Remote Config Contact Buttons
            if (supportPhone.isNotEmpty || supportEmail.isNotEmpty) ...[
              Row(
                children: [
                  if (supportPhone.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:$supportPhone');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: Text(context.l10n.callSupport),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (supportPhone.isNotEmpty && supportEmail.isNotEmpty)
                    const SizedBox(width: 12),
                  if (supportEmail.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('mailto:$supportEmail');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: Text(context.l10n.emailSupport),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Submit Ticket Action Card
            ElevatedButton.icon(
              onPressed: () => _showNewTicketSheet(context),
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: Text(context.l10n.contactSupport),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // My Tickets Section
            Text(
              context.l10n.myTickets,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<Complaint>>(
              stream: _complaintRepo.streamMyTickets(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = snapshot.data ?? [];
                if (tickets.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 40, color: context.themeTextSecondary),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.noTicketsYet,
                          style: TextStyle(
                            color: context.themeTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ticket = tickets[i];
                    final statusColor = _getStatusColor(ticket.status);
                    return Container(
                      decoration: BoxDecoration(
                        color: context.themeSurfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupportTicketDetailScreen(
                                  ticketId: ticket.id),
                            ),
                          );
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.effectiveSubject,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatusLabel(context, ticket.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Text(
                                ticket.effectiveType,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timeAgoL10n(context, ticket.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
