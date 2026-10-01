import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../services/chat_service.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/map_launcher.dart';
import '../../../shared/widgets/user_avatar.dart';

// Chat screen between customers and providers.
class DirectChatScreen extends StatefulWidget {
  final String otherPartyId;
  final String otherPartyName;
  final String? otherPartyRole;
  final String? otherPartyPhone;
  final String? jobRequestId;

  const DirectChatScreen({
    super.key,
    required this.otherPartyId,
    required this.otherPartyName,
    this.otherPartyRole,
    this.otherPartyPhone,
    this.jobRequestId,
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

  final List<String> _quickReplies = const [
    'Where are you now?',
    'I am waiting at the main gate.',
    'Please call me when you arrive.',
    'Parking is available on premise.',
    'On my way, will be there soon.',
  ];

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final currentUser = roleProvider.currentUser;
    if (currentUser == null) return;

    _currentUserId = currentUser.id;
    _currentUserName = currentUser.displayName.isNotEmpty
        ? currentUser.displayName
        : 'User';

    try {
      final chatId = await _chatService.getOrCreateChatRoom(
        userId1: _currentUserId,
        userId2: widget.otherPartyId,
        user1Name: _currentUserName,
        user2Name: widget.otherPartyName,
        jobRequestId: widget.jobRequestId,
        user1Role: currentUser.role == AppRole.provider
            ? (currentUser.serviceCategory ?? 'Service Provider')
            : 'Customer',
        user2Role: widget.otherPartyRole,
        user1Phone: currentUser.phone,
        user2Phone: widget.otherPartyPhone,
      );

      if (mounted) {
        setState(() {
          _chatRoomId = chatId;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to chat')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              uid: widget.otherPartyId,
              displayName: widget.otherPartyName,
              radius: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherPartyName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  Text(widget.otherPartyRole ?? 'Service Provider',
                      style: TextStyle(
                          fontSize: 11, color: context.themeTextSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.otherPartyPhone != null &&
              widget.otherPartyPhone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call, size: 20),
              tooltip: 'Call',
              onPressed: () =>
                  MapLauncher.openPhoneCall(widget.otherPartyPhone!),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_quickReplies[i],
                    style: const TextStyle(fontSize: 11)),
                onPressed: () => _sendMessage(_quickReplies[i]),
                backgroundColor: context.themeSurfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
          const SizedBox(height: 4),

          Expanded(child: _buildMessagesList()),

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
            Icon(Icons.chat_bubble_outline,
                size: 48, color: context.themeTextSecondary),
            const SizedBox(height: 8),
            Text('Could not load chat',
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
                Icon(Icons.chat_bubble_outline,
                    size: 48, color: context.themeTextSecondary),
                const SizedBox(height: 8),
                Text('Send a message to start chatting',
                    style: TextStyle(color: context.themeTextSecondary)),
              ],
            ),
          );
        }

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (_, index) {
            final msg = messages[index];
            final isMe = msg.senderId == _currentUserId;
            return _ChatBubble(
              text: msg.text,
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
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: context.themeSurface,
        border: Border(top: BorderSide(color: context.themeBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(color: context.themeTextSecondary),
                filled: true,
                fillColor: context.themeSurfaceContainer,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.onPrimary, size: 18),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String senderId;
  final String senderName;
  final DateTime? time;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.senderId,
    required this.senderName,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              uid: senderId,
              displayName: senderName,
              radius: 12,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : context.themeSurfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? AppColors.onPrimary : context.themeTextPrimary,
                      fontSize: 13,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 9,
                        color: isMe
                            ? AppColors.onPrimary.withValues(alpha: 0.7)
                            : context.themeTextSecondary,
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
