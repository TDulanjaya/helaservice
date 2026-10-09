import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as pv;
import '../../../services/chat_service.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../utils/l10n_extension.dart';
import '../../../models/complaint.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../services/category_service.dart';
import '../../../services/call_service.dart';


// direct chat screen
class DirectChatScreen extends StatefulWidget {
  final String otherPartyId;
  final String otherPartyName;
  final String? otherPartyRole;
  final String? otherPartyPhone;
  final String? jobRequestId;
  final String? bookingId;

  const DirectChatScreen({
    super.key,
    required this.otherPartyId,
    required this.otherPartyName,
    this.otherPartyRole,
    this.otherPartyPhone,
    this.jobRequestId,
    this.bookingId,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;

  String? _chatRoomId;
  String _currentUserId = '';
  String _currentUserName = '';
  bool _isInitializing = true;
  bool _isUploadingImage = false;

  final List<String> _quickReplies = const [
    'Where are you now?',
    'I am waiting at the main gate.',
    'Please call me when you arrive.',
    'Parking is available on premise.',
    'On my way, will be there soon.',
  ];

  bool get _isWithAdmin =>
      widget.otherPartyId == 'admin_support' ||
      widget.otherPartyRole?.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  void _showReportDialog(BuildContext context) {

    if (_isWithAdmin) return;
    final reasons = [
      context.l10n.complaintPriceDispute,
      context.l10n.complaintUnprofessionalConduct,
      context.l10n.complaintLateNoShow,
      context.l10n.complaintPoorQuality,
      context.l10n.complaintSafetyConcern,
      context.l10n.complaintFraudIssue,
      context.l10n.complaintOtherIssue,
    ];
    String selectedReason = reasons.first;
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ctx.themeSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.themeBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flag_rounded,
                            color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.reportIssueTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.reportIssueDesc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ctx.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.reportReasonPrompt,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ctx.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ctx.themeBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: ctx.themeSurface,
                        style: TextStyle(
                          color: ctx.themeTextPrimary,
                          fontSize: 13.5,
                        ),
                        items: reasons
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    minLines: 3,
                    maxLines: 5,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: ctx.themeTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.reportNotesPrompt,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: ctx.themeMuted,
                      ),
                      filled: true,
                      fillColor: ctx.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ctx.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);
                            try {
                              final roleProvider = pv.Provider.of<RoleProvider>(
                                  context,
                                  listen: false);
                              final currentUser = roleProvider.currentUser;
                              final currentUid = currentUser?.id ?? '';
                              final bool isCurrentProvider =
                                  currentUser?.role == AppRole.provider;
                              final String reporterRole =
                                  isCurrentProvider ? 'provider' : 'customer';
                              final String accusedRole =
                                  isCurrentProvider ? 'customer' : 'provider';

                              final complaint = Complaint(
                                customerId: isCurrentProvider
                                    ? widget.otherPartyId
                                    : currentUid,
                                customerName: isCurrentProvider
                                    ? widget.otherPartyName
                                    : (currentUser != null && currentUser.displayName.isNotEmpty
                                        ? currentUser.displayName
                                        : 'Customer'),
                                customerPhone: isCurrentProvider
                                    ? (widget.otherPartyPhone ?? '')
                                    : (currentUser?.phone ?? ''),
                                providerId: isCurrentProvider
                                    ? currentUid
                                    : widget.otherPartyId,
                                providerName: isCurrentProvider
                                    ? (currentUser != null && currentUser.displayName.isNotEmpty
                                        ? currentUser.displayName
                                        : 'Provider')
                                    : widget.otherPartyName,
                                providerTrade: 'Service Provider',
                                bookingId: widget.bookingId,
                                reason: selectedReason,
                                description:
                                    '${notesController.text.trim().isNotEmpty ? notesController.text.trim() : selectedReason} (Chat Room: $_chatRoomId)',
                                status: 'pending',
                                createdAt: DateTime.now(),
                                reporterRole: reporterRole,
                                accusedRole: accusedRole,
                              );

                              await ComplaintRepository()
                                  .submitComplaint(complaint);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        context.l10n.reportSuccessSnack),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.l10n.reportSubmitButton,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initChatRoom() async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final currentUser = roleProvider.currentUser;
    final fbUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.id ?? fbUser?.uid;

    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _isInitializing = false);
      return;
    }

    _currentUserId = uid;
    _currentUserName = (currentUser != null && currentUser.displayName.isNotEmpty)
        ? currentUser.displayName
        : (fbUser?.displayName?.isNotEmpty == true
            ? fbUser!.displayName!
            : 'User');

    // load cached id
    final ids = [_currentUserId, widget.otherPartyId]..sort();
    final deterministicChatId = '${ids[0]}_${ids[1]}';
    if (mounted) {
      setState(() {
        _chatRoomId = deterministicChatId;
        _isInitializing = false;
      });
    }

    try {
      final chatId = await _chatService.getOrCreateChatRoom(
        userId1: _currentUserId,
        userId2: widget.otherPartyId,
        user1Name: _currentUserName,
        user2Name: widget.otherPartyName,
        jobRequestId: widget.jobRequestId,
        user1Role: currentUser?.role == AppRole.provider
            ? (currentUser?.serviceCategory?.isNotEmpty == true
                ? CategoryService.instance.nameOf(currentUser!.serviceCategory!, context: context)
                : 'Service Provider')
            : 'Customer',
        user2Role: widget.otherPartyRole,
        user1Phone: currentUser?.phone,
        user2Phone: widget.otherPartyPhone,
      );

      if (mounted && _chatRoomId != chatId) {
        setState(() {
          _chatRoomId = chatId;
        });
      }

      // mark room as read on entrance
      if (_chatRoomId != null) {
        await _chatService.markRoomAsRead(_chatRoomId!, _currentUserId);
      }
    } catch (e) {
      debugPrint('Chat initialization warning: $e');
    }
  }

  // show photo picker sheet
  void _showImagePickerOptions(BuildContext context) {
    if (_isUploadingImage || _chatRoomId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ctx.themeSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ctx.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
                title: Text(
                  context.l10n.takePhoto,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.themeAmberTint,
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  context.l10n.chooseFromGallery,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // pick and upload photo message
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_chatRoomId == null || _currentUserId.isEmpty) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );

      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final file = File(picked.path);
      await _chatService.sendImageMessage(
        chatRoomId: _chatRoomId!,
        senderId: _currentUserId,
        senderName: _currentUserName,
        imageInput: file,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToUploadImage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _chatRoomId == null) return;

    _chatService.sendMessage(
      chatRoomId: _chatRoomId!,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: trimmed,
    );

    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // role label
  String _roleDisplay(BuildContext context, String? role) {
    final r = (role ?? '').trim().toLowerCase();
    if (r.isEmpty || r == 'service provider' || r == 'provider' || r == 'technician') {
      return context.l10n.custServiceProviderLabel;
    }
    if (r == 'customer') return context.l10n.customerLabel;
    return role!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: IconSquareButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        title: Row(
          children: [
            UserAvatar(
              uid: widget.otherPartyId,
              displayName: widget.otherPartyName,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPartyName,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _roleDisplay(context, widget.otherPartyRole),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.otherPartyPhone != null &&
              widget.otherPartyPhone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: IconSquareButton.small(
                  icon: Icons.call,
                  tooltip: context.l10n.call,
                  onTap: () {
                    CallService.instance.startCall(
                      context: context,
                      calleePhone: widget.otherPartyPhone!,
                      calleeName: widget.otherPartyName,
                      bookingId: widget.bookingId,
                      calleeUid: widget.otherPartyId,
                      calleeRole: widget.otherPartyRole,
                    );
                  },
                ),
              ),
            ),
          if (!_isWithAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: IconSquareButton.small(
                  icon: Icons.flag_outlined,
                  tooltip: context.l10n.reportToAdmin,
                  onTap: () => _showReportDialog(context),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isWithAdmin)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.adminSupportChannelSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Official Support',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_isWithAdmin && widget.jobRequestId != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final text =
                      _getLocalizedQuickReply(context, _quickReplies[i]);
                  return ActionChip(
                    label: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    onPressed: () => _sendMessage(text),
                    backgroundColor: context.themeSurface,
                    side: BorderSide(color: context.themeBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 6),

          Expanded(child: _buildMessagesList()),

          if (_isUploadingImage)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: context.themeBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chatRoomId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.couldNotLoadChat,
                style: TextStyle(color: context.themeTextSecondary)),
          ],
        ),
      );
    }

    return StreamBuilder<List<ChatMessageModel>>(
      stream: _chatService.streamMessages(_chatRoomId!),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                Text(context.l10n.sendMsgToStartChat,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary)),
              ],
            ),
          );
        }

        // mark as read on messages stream update
        if (_chatRoomId != null && _currentUserId.isNotEmpty) {
          _chatService.markRoomAsRead(_chatRoomId!, _currentUserId);
        }

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: messages.length,
          itemBuilder: (_, index) {
            final msg = messages[index];
            final isMe = msg.senderId == _currentUserId;
            return _ChatBubble(
              text: msg.text,
              imageUrl: msg.imageUrl,
              isMe: isMe,
              senderId: msg.senderId,
              senderName: msg.senderName,
              time: msg.createdAt,
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: context.themeSurface,
        border: Border(top: BorderSide(color: context.themeBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 22),
            color: context.themeTextSecondary,
            tooltip: context.l10n.sendPhoto,
            onPressed: _isUploadingImage ? null : () => _showImagePickerOptions(context),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: context.l10n.typeMessage,
                hintStyle: TextStyle(color: context.themeTextSecondary),
                filled: true,
                fillColor: context.themeSurfaceLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: context.themeBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: context.themeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.onPrimary, size: 19),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedQuickReply(BuildContext context, String reply) {
    switch (reply) {
      case 'Where are you now?':
        return context.l10n.quickReplyWhereAreYou;
      case 'I am waiting at the main gate.':
        return context.l10n.quickReplyWaitingMainGate;
      case 'Please call me when you arrive.':
        return context.l10n.quickReplyCallWhenArrive;
      case 'Parking is available on premise.':
        return context.l10n.quickReplyParkingAvailable;
      case 'On my way, will be there soon.':
        return context.l10n.quickReplyOnMyWay;
      default:
        return reply;
    }
  }
}

// chat bubble supporting text and photos
class _ChatBubble extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final bool isMe;
  final String senderId;
  final String senderName;
  final DateTime? time;

  const _ChatBubble({
    required this.text,
    this.imageUrl,
    required this.isMe,
    required this.senderId,
    required this.senderName,
    this.time,
  });

  // open full screen image viewer
  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              context.l10n.viewPhoto,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              uid: senderId,
              displayName: senderName,
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: hasImage
                  ? const EdgeInsets.all(6)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : context.themeSurfaceLow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe
                      ? AppColors.primary
                      : context.themeBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage) ...[
                    GestureDetector(
                      onTap: () => _openFullScreenImage(context, imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 240,
                            maxWidth: 240,
                          ),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 180,
                                width: 220,
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 120,
                              width: 200,
                              color: Colors.black12,
                              child: const Icon(Icons.broken_image, size: 36),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (text.isNotEmpty) const SizedBox(height: 6),
                  ],
                  if (text.isNotEmpty)
                    Padding(
                      padding: hasImage
                          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                          : EdgeInsets.zero,
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isMe ? AppColors.onPrimary : context.themeTextPrimary,
                          fontSize: 13.5,
                          fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  if (time != null) ...[
                    const SizedBox(height: 3),
                    Padding(
                      padding: hasImage
                          ? const EdgeInsets.symmetric(horizontal: 6)
                          : EdgeInsets.zero,
                      child: Text(
                        '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isMe
                              ? AppColors.onPrimary.withValues(alpha: 0.7)
                              : context.themeTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

