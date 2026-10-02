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

    final roleTag = isSuperAdmin
        ? 'Super Admin • Platform Governance'
        : (adminUser != null
            ? '${adminUser.role.label} • Operations'
            : 'Operations Admin');

    final permissions = isSuperAdmin
        ? AdminPermission.values
        : (adminUser?.permissions ?? []);

    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        isMobile ? AppBottomNav.contentBottomPadding : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.l10n.adminConsole,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              InkWell(
                onTap: () => showRoleSwitchSheet(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: context.themeTextPrimary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 18 : 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeHeroSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.themeHeroBorder),
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
                      editable: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            roleTag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.themeAmberText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (permissions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Assigned Permissions:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: permissions.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.label,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 26),
          Text(
            context.l10n.operationsControls.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.themeBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.people_outline_rounded,
                  iconBg: context.themeAmberTint,
                  iconColor: context.themeAmberText,
                  title: context.l10n.adminTeamGovernance,
                  subtitle: context.l10n.adminTeamGovernanceDesc,
                  onTap: () {
                    if (onNavigateToAdmins != null) {
                      onNavigateToAdmins!();
                    }
                  },
                ),
                if (roleProvider.hasAdminPermission(AdminPermission.broadcastAlerts)) ...[
                  Divider(height: 1, color: context.themeBorder),
                  _SettingsTile(
                    icon: Icons.campaign_outlined,
                    iconBg: context.themeAmberTint,
                    iconColor: context.themeAmberText,
                    title: context.l10n.emergencyBroadcast,
                    subtitle: context.l10n.emergencyBroadcastDesc,
                    onTap: () => _showBroadcastDialog(context),
                  ),
                ],
                Divider(height: 1, color: context.themeBorder),
                _SettingsTile(
                  icon: Icons.receipt_long_outlined,
                  iconBg: context.themeSoft,
                  iconColor: AppColors.primary,
                  title: context.l10n.auditLogs,
                  subtitle: 'Review administrator actions & access history',
                  onTap: () {
                    if (isSuperAdmin) {
                      _showAuditLogsSheet(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Access Denied: Platform audit logs are restricted to Super Admins.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 26),
          Text(
            'PREFERENCES & APPEARANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.themeBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                pv.Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _SettingsTile(
                      icon: themeProvider.isDark(context)
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      title: context.l10n.themeMode,
                      subtitle:
                          'Current: ${themeProvider.getModeDisplayName(context)}',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: context.themeSurface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (sheetCtx) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.themeMode,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: const Icon(Icons.brightness_auto),
                                    title: Text(context.l10n.themeSystem),
                                    trailing:
                                        themeProvider.mode == ThemeMode.system
                                            ? const Icon(
                                                Icons.check,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                    onTap: () {
                                      themeProvider.setSystem();
                                      Navigator.pop(sheetCtx);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.light_mode),
                                    title: Text(context.l10n.themeLight),
                                    trailing:
                                        themeProvider.mode == ThemeMode.light
                                            ? const Icon(
                                                Icons.check,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                    onTap: () {
                                      themeProvider.setLight();
                                      Navigator.pop(sheetCtx);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.dark_mode),
                                    title: Text(context.l10n.themeDark),
                                    trailing:
                                        themeProvider.mode == ThemeMode.dark
                                            ? const Icon(
                                                Icons.check,
                                                color: AppColors.primary,
                                              )
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
                Divider(height: 1, color: context.themeBorder),
                pv.Consumer<LocaleProvider>(
                  builder: (context, localeProvider, _) {
                    return _SettingsTile(
                      icon: Icons.language,
                      title: 'App Language / භාෂාව / மொழி',
                      subtitle: localeProvider.languageDisplayName,
                      onTap: () => LanguageSelectSheet.show(context),
                    );
                  },
                ),
                Divider(height: 1, color: context.themeBorder),
                _SettingsTile(
                  icon: Icons.swap_horiz,
                  title: context.l10n.switchOperationalView,
                  subtitle: context.l10n.switchOperationalViewDesc,
                  onTap: () => showRoleSwitchSheet(context),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              label: Text(
                context.l10n.logout,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: context.themeDangerTint.withValues(alpha: 0.2),
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBg;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg ?? context.themeSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor ?? context.themeTextPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.themeTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
