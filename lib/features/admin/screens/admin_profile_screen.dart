import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../models/admin_user.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../state/theme_provider.dart';
import '../../../state/locale_provider.dart';
import '../../../shared/widgets/language_select_sheet.dart';
import '../../../app_router.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_avatar.dart';

class AdminProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToVerifications;
  final VoidCallback? onNavigateToAdmins;

  const AdminProfileScreen({
    super.key,
    this.onNavigateToVerifications,
    this.onNavigateToAdmins,
  });

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              pv.Provider.of<RoleProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(context.l10n.broadcastAlert, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.broadcastAlertDesc,
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Weather warning: Heavy rain alert in Western Province...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = messageController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an alert message.')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection(FirestorePaths.dispatchEvents)
                    .add({
                  'title': 'Emergency Broadcast',
                  'detail': text,
                  'tagLabel': 'ALERT',
                  'timeAgo': 'Just now',
                  'iconKey': 'bolt',
                  'colorValue': 0xFFD6900F,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Broadcast alert dispatched and recorded in live operations feed.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to dispatch broadcast: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.sendBroadcast),
          ),
        ],
      ),
    );
  }

  void _showAuditLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetCtx).size.height * 0.75,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(FirestorePaths.dispatchEvents)
                .orderBy('timestamp', descending: true)
                .limit(40)
                .snapshots(),
            builder: (ctx, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.security, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.auditLogs,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${docs.length} Recent Governance & Dispatch Records',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (docs.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy_all, size: 20),
                            tooltip: 'Export Audit Log (JSON)',
                            onPressed: () {
                              final logData = docs.map((d) {
                                final data = d.data();
                                return {
                                  'id': d.id,
                                  'title': data['title'] ?? '',
                                  'detail': data['detail'] ?? '',
                                  'tagLabel': data['tagLabel'] ?? '',
                                  'author': data['author'] ?? '',
                                  'timestamp': data['timestamp'] != null
                                      ? (data['timestamp'] as Timestamp)
                                          .toDate()
                                          .toIso8601String()
                                      : null,
                                };
                              }).toList();
                              Clipboard.setData(
                                ClipboardData(text: jsonEncode(logData)),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Audit log exported to clipboard as JSON.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: docs.isEmpty
                        ? (snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.shield_outlined,
                                        size: 40, color: AppColors.outline),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No platform audit logs recorded yet.',
                                      style: TextStyle(
                                        color: context.themeTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final d = docs[i].data();
                              final title = d['title'] as String? ?? 'System Action';
                              final detail = d['detail'] as String? ?? '';
                              final tag = d['tagLabel'] as String? ?? 'AUDIT';
                              final author = d['author'] as String?;
                              final ts = d['timestamp'];
                              final dateStr = ts is Timestamp
                                  ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')} • ${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                                  : (d['timeAgo'] as String? ?? 'Recent');

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.history, color: AppColors.primary, size: 18),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.themeSurfaceContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (detail.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(detail, style: TextStyle(fontSize: 11.5, color: context.themeTextPrimary)),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${author != null ? 'By: $author • ' : ''}$dateStr',
                                      style: TextStyle(fontSize: 10, color: context.themeTextSecondary),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;
    final adminUser = roleProvider.currentAdminUser;
    final isSuperAdmin = roleProvider.isSuperAdmin;

    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (adminUser?.displayName.isNotEmpty == true
            ? adminUser!.displayName
            : 'Administrator');
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : (adminUser?.email ?? '');

    final roleColor = adminUser?.roleColor ?? AppColors.primary;
    final roleTag = isSuperAdmin
        ? 'Super Admin • Platform Governance'
        : (adminUser != null ? adminUser.role.label : 'Operations Admin');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.adminConsole,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: context.l10n.switchRole,
            onPressed: () => showRoleSwitchSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).size.width < 768
                ? AppBottomNav.contentBottomPadding
                : 24,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        uid: user?.id ?? adminUser?.id,
                        displayName: displayName,
                        photoUrl: user?.photoUrl,
                        radius: 32,
                        backgroundColor: roleColor.withValues(alpha: 0.15),
                        textColor: roleColor,
                        editable: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                roleTag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (adminUser != null && !isSuperAdmin) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    const Text(
                      'Assigned Permissions:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: adminUser.permissions.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            p.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.operationsControls,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _AdminActionTile(
              icon: Icons.shield_outlined,
              title: context.l10n.adminTeamGovernance,
              subtitle: context.l10n.adminTeamGovernanceDesc,
              onTap: () {
                if (onNavigateToAdmins != null) {
                  onNavigateToAdmins!();
                }
              },
            ),
            if (roleProvider.hasAdminPermission(AdminPermission.broadcastAlerts))
              _AdminActionTile(
                icon: Icons.campaign_outlined,
                title: context.l10n.emergencyBroadcast,
                subtitle: context.l10n.emergencyBroadcastDesc,
                onTap: () => _showBroadcastDialog(context),
              ),
            _AdminActionTile(
              icon: Icons.security_outlined,
              title: context.l10n.auditLogs,
              subtitle: 'Review administrator actions & access history',
              onTap: () {
                if (isSuperAdmin) {
                  _showAuditLogsSheet(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Access Denied: Platform audit logs are restricted to Super Admins.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.appearance,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.themeBorder),
              ),
              child: pv.Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDark(context)
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(context.l10n.themeMode,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${context.l10n.currentTheme}: ${themeProvider.getModeDisplayName(context)} (${context.l10n.tapToChange})',
                      style: TextStyle(
                          fontSize: 11.5, color: context.themeTextSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: context.themeSurface,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (sheetCtx) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.themeMode,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: const Icon(Icons.brightness_auto),
                                  title: Text(context.l10n.themeSystem),
                                  trailing: themeProvider.mode == ThemeMode.system
                                      ? const Icon(Icons.check,
                                          color: AppColors.primary)
                                      : null,
                                  onTap: () {
                                    themeProvider.setSystem();
                                    Navigator.pop(sheetCtx);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.light_mode),
                                  title: Text(context.l10n.themeLight),
                                  trailing: themeProvider.mode == ThemeMode.light
                                      ? const Icon(Icons.check,
                                          color: AppColors.primary)
                                      : null,
                                  onTap: () {
                                    themeProvider.setLight();
                                    Navigator.pop(sheetCtx);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.dark_mode),
                                  title: Text(context.l10n.themeDark),
                                  trailing: themeProvider.mode == ThemeMode.dark
                                      ? const Icon(Icons.check,
                                          color: AppColors.primary)
                                      : null,
                                  onTap: () {
                                    themeProvider.setDark();
                                    Navigator.pop(sheetCtx);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
              ),
              child: pv.Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  return ListTile(
                    leading: const Icon(Icons.language,
                        color: AppColors.primary),
                    title: Text(context.l10n.appLanguage,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${context.l10n.currentLanguage}: ${localeProvider.languageDisplayName} (${context.l10n.tapToChange})',
                      style: TextStyle(
                          fontSize: 12, color: context.themeTextSecondary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.outline),
                    onTap: () => LanguageSelectSheet.show(context),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
            Text(
              context.l10n.switchRole,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => showRoleSwitchSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: context.themeBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_horiz,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.switchOperationalView,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.switchOperationalViewDesc,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: context.themeTextSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: Text(
                context.l10n.logout,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              fontSize: 11.5, color: context.themeTextSecondary),
        ),
        trailing:
            Icon(Icons.chevron_right, size: 18, color: context.themeTextSecondary),
      ),
    );
  }
}
