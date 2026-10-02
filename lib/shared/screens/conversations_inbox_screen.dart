import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;

import '../../features/customer/screens/direct_chat_screen.dart';
import '../../services/chat_service.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/map_launcher.dart';
import '../widgets/user_avatar.dart';
import '../widgets/icon_square_button.dart';
import '../widgets/app_card.dart';

class ConversationsInboxScreen extends StatefulWidget {
  const ConversationsInboxScreen({super.key});

  @override
  State<ConversationsInboxScreen> createState() =>
      _ConversationsInboxScreenState();
}

class _ConversationsInboxScreenState extends State<ConversationsInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final currentUser = roleProvider.currentUser;
    final fbUser = FirebaseAuth.instance.currentUser;
    final effectiveUid = (fbUser?.uid.isNotEmpty == true)
        ? fbUser!.uid
        : (currentUser?.id ?? '');
    final bool isUserAuthenticated = fbUser != null;

    final onSurfaceVar = context.themeTextSecondary;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  IconSquareButton(
                    icon: Icons.chevron_left_rounded,
                    size: 44,
                    iconSize: 26,
                    radius: 14,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: context.themeInk,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                style: TextStyle(color: context.themeInk, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search chats by name or message...',
                  hintStyle: TextStyle(
                    color: context.themeMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.themeMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          color: context.themeMuted,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.themeSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.themeBorder, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.themeBorder, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chat list

            Expanded(
              child: !isUserAuthenticated || effectiveUid.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 48, color: onSurfaceVar),
                            const SizedBox(height: 16),
                            Text(
                              'Please sign in to view your messages',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.themeInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : StreamBuilder<List<ChatRoomSummary>>(
                      stream: roleProvider.isAuthorizedAdmin
                          ? ChatService.instance.streamAllChatRooms()
                          : ChatService.instance.streamUserChatRooms(effectiveUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Failed to load conversations: ${snapshot.error}',
                                style: const TextStyle(color: AppColors.danger),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final rooms = snapshot.data ?? [];
                        final filtered = rooms.where((r) {
                          if (_searchQuery.isEmpty) return true;
                          final otherName =
                              r.getOtherPartyName(effectiveUid).toLowerCase();
                          final lastMsg = r.lastMessage.toLowerCase();
                          final role =
                              (r.getOtherPartyRole(effectiveUid) ?? '').toLowerCase();
                          return otherName.contains(_searchQuery) ||
                              lastMsg.contains(_searchQuery) ||
                              role.contains(_searchQuery);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: context.themeAmberTint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 38,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No matching conversations'
                                        : 'No conversations yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeInk,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Direct messages with service providers or customers will appear here.'
                                        : 'Try searching with another name or keyword.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: onSurfaceVar,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                color: context.themeBorder,
                                height: 16,
                                thickness: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final room = filtered[index];
                                final otherPartyId = room.getOtherPartyId(effectiveUid);
                                final otherPartyName =
                                    room.getOtherPartyName(effectiveUid);
                                final otherPartyRole =
                                    room.getOtherPartyRole(effectiveUid);
                                final otherPartyPhone =
                                    room.getOtherPartyPhone(effectiveUid);
                                final lastMessage = room.lastMessage.trim();
                                final timeAgo = _formatTimeAgo(room.lastMessageAt);
                                final isJustNow = timeAgo == 'Just now';

                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DirectChatScreen(
                                          otherPartyId: otherPartyId,
                                          otherPartyName: otherPartyName,
                                          otherPartyRole: otherPartyRole,
                                          otherPartyPhone: otherPartyPhone,
                                          jobRequestId: room.jobRequestId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        UserAvatar(
                                          uid: otherPartyId,
                                          displayName: otherPartyName,
                                          radius: 24,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      otherPartyName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 15,
                                                        color: context.themeInk,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (timeAgo.isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      timeAgo,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: isJustNow
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        color: isJustNow
                                                            ? context.themeAmberText
                                                            : context.themeMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                lastMessage.isNotEmpty
                                                    ? lastMessage
                                                    : 'Tap to start conversation',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: lastMessage.isNotEmpty
                                                      ? context.themeTextSecondary
                                                      : context.themeMuted,
                                                  fontStyle: lastMessage.isEmpty
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (otherPartyPhone != null &&
                                            otherPartyPhone.trim().isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          IconSquareButton.small(
                                            icon: Icons.phone_outlined,
                                            tooltip: 'Call $otherPartyName',
                                            onTap: () {
                                              MapLauncher.openPhoneCall(
                                                  otherPartyPhone);
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

