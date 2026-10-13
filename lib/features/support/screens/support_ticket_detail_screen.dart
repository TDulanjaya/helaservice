import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/complaint.dart';
import '../../../models/support_message.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';
import '../../../utils/ticket_error_l10n.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _complaintRepo = ComplaintRepository();
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSending = false;
  PickedAttachment? _selectedPhoto;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedPhoto == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    try {
      final photoUrls = <String>[];
      if (_selectedPhoto != null) {
        try {
          final storage = StorageService();
          final url = await storage.uploadPickedAttachment(
            _selectedPhoto!,
            purpose: 'job_photo',
          );
          photoUrls.add(url);
        } catch (e) {
          debugPrint('[SupportTicketDetailScreen] Photo upload failed: $e');
          setState(() => _isSending = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.ticketPhotoUploadFailed),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      final msg = SupportMessage(
        senderUid: user.uid,
        senderRole: 'user',
        text: text,
        photos: photoUrls,
        createdAt: DateTime.now(),
      );

      await _complaintRepo.addMessage(widget.ticketId, msg);
      _textController.clear();
      setState(() {
        _selectedPhoto = null;
        _isSending = false;
      });
    } catch (e) {
      debugPrint('[SupportTicketDetailScreen] Failed to send message: $e');
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ticketErrorMessage(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.ticketCloseConfirm),
        content: const Text('Are you sure you want to close this ticket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.ticketCloseConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _complaintRepo.closeTicket(widget.ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket closed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return StreamBuilder<Complaint?>(
      stream: _complaintRepo.streamTicket(widget.ticketId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.themeSurface,
            appBar: AppBar(backgroundColor: context.themeSurface),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final ticket = snapshot.data;
        if (ticket == null) {
          return Scaffold(
            backgroundColor: context.themeSurface,
            appBar: AppBar(backgroundColor: context.themeSurface),
            body: const Center(child: Text('Ticket not found')),
          );
        }

        final statusColor = _getStatusColor(ticket.status);
        final isClosed = ticket.isClosed;

        return Scaffold(
          backgroundColor: context.themeSurface,
          appBar: AppBar(
            title: Text(ticket.effectiveSubject),
            backgroundColor: context.themeSurface,
            actions: [
              if (!isClosed && ticket.effectiveReporterUid == uid)
                TextButton(
                  onPressed: _closeTicket,
                  child: Text(
                    context.l10n.ticketCloseConfirm,
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Ticket Header Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  border: Border(bottom: BorderSide(color: context.themeBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
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
                        const SizedBox(width: 8),
                        Text(
                          'Type: ${ticket.effectiveType}',
                          style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                        ),
                        const Spacer(),
                        Text(
                          timeAgoL10n(context, ticket.createdAt),
                          style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (ticket.photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ticket.photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ticket.photos[i],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (ticket.resolutionNote != null && ticket.resolutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${context.l10n.ticketResolvedNote}: ${ticket.resolutionNote}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: StreamBuilder<List<SupportMessage>>(
                  stream: _complaintRepo.streamMessages(widget.ticketId),
                  builder: (context, msgSnap) {
                    final messages = msgSnap.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          context.l10n.ticketReplyPrompt,
                          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        final isMe = m.senderUid == uid;
                        final isAdmin = m.isAdmin;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primary
                                  : (isAdmin
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : context.themeSurfaceLow),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isMe
                                    ? AppColors.primary
                                    : context.themeBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAdmin)
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'HelaService Support',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (m.text.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: isAdmin ? 4 : 0),
                                    child: Text(
                                      m.text,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : context.themeInk,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                if (m.photos.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: m.photos.map((pUrl) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(pUrl, width: 80, height: 80, fit: BoxFit.cover),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    timeAgoL10n(context, m.createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : context.themeTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Reply Composer
              if (!isClosed)
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    border: Border(top: BorderSide(color: context.themeBorder)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedPhoto != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(_selectedPhoto!.bytes, width: 44, height: 44, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _selectedPhoto = null),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_a_photo_outlined),
                            onPressed: () async {
                              final img = await _picker.pickImage(source: ImageSource.gallery);
                              if (img != null) {
                                final bytes = await img.readAsBytes();
                                setState(() => _selectedPhoto = PickedAttachment(file: img, bytes: bytes));
                              }
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: 3,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: context.l10n.ticketReplyHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: context.themeBorder),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded, color: AppColors.primary),
                            onPressed: _isSending ? null : _sendMessage,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  color: context.themeSurfaceLow,
                  child: Center(
                    child: Text(
                      'This ticket is closed.',
                      style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
