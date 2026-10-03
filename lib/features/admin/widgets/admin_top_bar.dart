import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../models/admin_models.dart';
import '../../../models/admin_user.dart';
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';
import '../../../shared/widgets/user_avatar.dart';

class AdminTopBar extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const AdminTopBar({super.key, this.onSearchTap, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final adminUser = roleProvider.currentAdminUser;
    final adminName = adminUser?.displayName.isNotEmpty == true
        ? adminUser!.displayName
        : (roleProvider.currentUser?.displayName.isNotEmpty == true
            ? roleProvider.currentUser!.displayName
            : context.l10n.topBarAdministrator);
    final adminRole = adminUser != null
        ? (adminUser.isSuperAdmin
            ? context.l10n.roleSuperAdminBadge
            : (adminUser.role == AdminRole.opsAdmin
                ? context.l10n.roleOpsAdminBadge
                : context.l10n.roleSupportAdminBadge))
        : context.l10n.roleSuperAdminBadge;

    if (isMobile) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.themeBg,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HelaService Ops',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: context.themeTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  context.l10n.opsCoreSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.themeSurface,
                shape: BoxShape.circle,
                border: Border.all(color: context.themeBorder),
              ),
              child: IconButton(
                icon: Icon(Icons.search, size: 18, color: context.themeTextPrimary),
                onPressed: onSearchTap ?? () {},
                tooltip: context.l10n.topBarSearch,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.themeSurface,
                shape: BoxShape.circle,
                border: Border.all(color: context.themeBorder),
              ),
              child: IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    size: 18, color: context.themeTextPrimary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ConversationsInboxScreen(),
                    ),
                  );
                },
                tooltip: context.l10n.messages,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onProfileTap ?? () => showRoleSwitchSheet(context),
              child: UserAvatar(
                uid: roleProvider.currentUser?.id ?? adminUser?.id,
                displayName: adminName,
                photoUrl: roleProvider.currentUser?.photoUrl,
                radius: 17,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.themeSurface,
        border: Border(bottom: BorderSide(color: context.themeBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 38,
            decoration: BoxDecoration(
              color: context.themeSurfaceLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(children: [
              Icon(Icons.search, size: 16, color: context.themeTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.searchTechniciansNicJobs,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.l10n.islandNetworkStatus,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showNotificationPanel(context),
            icon: Icon(Icons.notifications_none,
                color: context.themeTextSecondary),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationsInboxScreen(),
                ),
              );
            },
            icon: Icon(Icons.chat_bubble_outline,
                color: context.themeTextSecondary),
            tooltip: context.l10n.topBarSupportMessages,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onProfileTap ?? () => showRoleSwitchSheet(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(
                  uid: roleProvider.currentUser?.id ?? adminUser?.id,
                  displayName: adminName,
                  photoUrl: roleProvider.currentUser?.photoUrl,
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        adminRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10, color: context.themeTextSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    size: 16, color: context.themeTextSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(context.l10n.operationsAlertsBroadcasts,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(FirestorePaths.dispatchEvents)
                      .orderBy('timestamp', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                              context.l10n.noActiveSystemAlerts,
                              style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 13)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        final event = DispatchEvent.fromMap(docs[i].id, data);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                event.iconColor.withValues(alpha: 0.15),
                            child: Icon(event.icon,
                                color: event.iconColor, size: 18),
                          ),
                          title: Text(event.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(event.detail,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.themeTextSecondary)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  timeAgoL10n(context, event.timestamp,
                                      fallback: event.timeAgo),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: context.themeTextSecondary)),
                              if (event.tagLabel.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: event.iconColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(event.tagLabel,
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: event.iconColor)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
