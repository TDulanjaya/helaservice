import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;

import '../../features/customer/screens/direct_chat_screen.dart';
import '../../features/support/screens/help_support_screen.dart';
import '../../services/chat_service.dart';
import '../../services/session_guard.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/map_launcher.dart';
import '../widgets/user_avatar.dart';
import '../widgets/icon_square_button.dart';
import '../widgets/app_card.dart';
import '../../utils/l10n_extension.dart';

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

  String _formatTimeAgo(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.l10n.timeJustNow;
    if (diff.inMinutes < 60) return context.l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return context.l10n.timeDaysAgo(diff.inDays);
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
            // header
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
                    context.l10n.messages,
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

            // search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                style: TextStyle(color: context.themeInk, fontSize: 14),
                decoration: InputDecoration(
                  hintText: context.l10n.searchChatsPlaceholder,
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
                    borderSide:
                        BorderSide(color: context.themeBorder, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: context.themeBorder, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (!roleProvider.isAuthorizedAdmin)
              _buildAdminSupportCard(context),

            // chat list
            Expanded(
              child: !isUserAuthenticated || effectiveUid.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 48, color: onSurfaceVar),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n.signInToViewMessages,
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
                          : ChatService.instance
                              .streamUserChatRooms(effectiveUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.hasError) {
                          SessionGuard.handlePermissionDenied(snapshot.error);
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                '${context.l10n.failedToLoadConversations}: ${snapshot.error}',
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
                          final role = (r.getOtherPartyRole(effectiveUid) ?? '')
                              .toLowerCase();
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
                                        ? context.l10n.noMatchingConversations
                                        : context.l10n.noConversationsYet,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeInk,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? context.l10n.conversationsEmptyDesc
                                        : context
                                            .l10n.trySearchingAnotherKeyword,
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
                                final otherPartyId =
                                    room.getOtherPartyId(effectiveUid);
                                final otherPartyName =
                                    room.getOtherPartyName(effectiveUid);
                                final otherPartyRole =
                                    room.getOtherPartyRole(effectiveUid);
                                final otherPartyPhone =
                                    room.getOtherPartyPhone(effectiveUid);
                                final lastMessage = room.lastMessage.trim();
                                final unreadCount =
                                    room.getUnreadCount(effectiveUid);
                                final hasUnread = unreadCount > 0;
                                final isJustNow = room.lastMessageAt != null &&
                                    DateTime.now()
                                            .difference(room.lastMessageAt!)
                                            .inMinutes <
                                        1;
                                final timeAgo =
                                    _formatTimeAgo(context, room.lastMessageAt);

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                                        fontWeight: hasUnread
                                                            ? FontWeight.w800
                                                            : FontWeight.w700,
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
                                                        fontWeight:
                                                            (isJustNow ||
                                                                    hasUnread)
                                                                ? FontWeight
                                                                    .w700
                                                                : FontWeight
                                                                    .w500,
                                                        color: hasUnread
                                                            ? AppColors.primary
                                                            : (isJustNow
                                                                ? context
                                                                    .themeAmberText
                                                                : context
                                                                    .themeMuted),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  if (lastMessage == 'photo' ||
                                                      lastMessage ==
                                                          'Photo') ...[
                                                    Icon(
                                                      Icons
                                                          .photo_camera_rounded,
                                                      size: 14,
                                                      color: hasUnread
                                                          ? context.themeInk
                                                          : context
                                                              .themeTextSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                  ],
                                                  Expanded(
                                                    child: Text(
                                                      lastMessage.isNotEmpty
                                                          ? ((lastMessage ==
                                                                      'photo' ||
                                                                  lastMessage ==
                                                                      'Photo')
                                                              ? context.l10n
                                                                  .chatPhotoMessage
                                                              : lastMessage)
                                                          : context.l10n
                                                              .tapToStartConversation,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: hasUnread
                                                            ? FontWeight.w700
                                                            : FontWeight.normal,
                                                        color: hasUnread
                                                            ? context.themeInk
                                                            : (lastMessage.isNotEmpty
                                                                ? context
                                                                    .themeTextSecondary
                                                                : context
                                                                    .themeMuted),
                                                        fontStyle: lastMessage
                                                                .isEmpty
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (hasUnread) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 7,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Text(
                                                        unreadCount > 99
                                                            ? '99+'
                                                            : unreadCount
                                                                .toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (otherPartyPhone != null &&
                                            otherPartyPhone
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          IconSquareButton.small(
                                            icon: Icons.phone_outlined,
                                            tooltip:
                                                '${context.l10n.call} $otherPartyName',
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

  Widget _buildAdminSupportCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpSupportScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              context.l10n.adminSupportChannelTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: context.themeInk,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OFFICIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.adminSupportChannelSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
