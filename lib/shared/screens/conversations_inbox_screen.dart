import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;

import '../../features/customer/screens/direct_chat_screen.dart';
import '../../services/chat_service.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/map_launcher.dart';
import '../widgets/user_avatar.dart';

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

    final surfaceColor = AppColors.getSurface(context);
    final onSurface = AppColors.getTextPrimary(context);
    final onSurfaceVar = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              style: TextStyle(color: onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search chats by name or message...',
                hintStyle: TextStyle(
                    color: onSurfaceVar.withValues(alpha: 0.6), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: onSurfaceVar, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.getSurfaceLow(context),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: !isUserAuthenticated || effectiveUid.isEmpty
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
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
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
                        style: const TextStyle(color: AppColors.error),
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching conversations'
                                : 'No conversations yet',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Direct messages with service providers or customers will appear here.'
                                : 'Try searching with another name or keyword.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: onSurfaceVar,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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

                    return Material(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
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
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                uid: otherPartyId,
                                displayName: otherPartyName,
                                radius: 24,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            otherPartyName,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (timeAgo.isNotEmpty)
                                          Text(
                                            timeAgo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: onSurfaceVar.withValues(
                                                  alpha: 0.8),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    if (otherPartyRole != null &&
                                        otherPartyRole.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          otherPartyRole,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      lastMessage.isNotEmpty
                                          ? lastMessage
                                          : 'Tap to start conversation',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: lastMessage.isNotEmpty
                                            ? onSurfaceVar
                                            : onSurfaceVar.withValues(
                                                alpha: 0.5),
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
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Call $otherPartyName',
                                  onPressed: () {
                                    MapLauncher.openPhoneCall(otherPartyPhone);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
