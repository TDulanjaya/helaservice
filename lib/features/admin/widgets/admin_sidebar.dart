import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../models/admin_user.dart';
import '../../../utils/l10n_extension.dart';

class AdminNavEntry {
  final IconData icon;
  final String label;
  final String? badge;
  const AdminNavEntry(this.icon, this.label, {this.badge});
}

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AdminSidebar(
      {super.key, required this.selectedIndex, required this.onSelect});

  static const entries = [
    AdminNavEntry(Icons.grid_view_rounded, 'Dashboard'),
    AdminNavEntry(Icons.badge_outlined, 'Verifications'),
    AdminNavEntry(Icons.manage_accounts_outlined, 'Users & Bans'),
    AdminNavEntry(Icons.layers_outlined, 'Coverage & Categories'),
    AdminNavEntry(Icons.people_outline, 'Admins & Team'),
    AdminNavEntry(Icons.format_list_bulleted, 'Job Ledger'),
    AdminNavEntry(Icons.warning_amber_rounded, 'Disputes & Reports'),
    AdminNavEntry(Icons.tune, 'Platform Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    String getLocalizedLabel(int index) {
      switch (index) {
        case 0:
          return context.l10n.navDashboard;
        case 1:
          return context.l10n.navVerifications;
        case 2:
          return context.l10n.navUserManagement;
        case 3:
          return context.l10n.navCoverageAndCategories;
        case 4:
          return context.l10n.navAdminsAndTeam;
        case 5:
          return context.l10n.jobLedgerNav;
        case 6:
          return context.l10n.navDisputes;
        case 7:
          return context.l10n.navPlatformSettings;
        default:
          return entries[index].label;
      }
    }

    final roleProvider = pv.Provider.of<RoleProvider>(context);
    bool isRestricted(int i) {
      if (roleProvider.isSuperAdmin) return false;
      switch (i) {
        case 1:
          return !roleProvider.hasAdminPermission(AdminPermission.verifyNic);
        case 2:
          return false;
        case 3:
          return !roleProvider
              .hasAdminPermission(AdminPermission.manageCategories);
        case 4:
          return !roleProvider.isSuperAdmin;
        case 5:
          return !roleProvider.hasAdminPermission(AdminPermission.viewFinances);
        case 6:
          return !roleProvider
              .hasAdminPermission(AdminPermission.handleSupport);
        default:
          return false;
      }
    }

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: context.themeSurface,
        border: Border(right: BorderSide(color: context.themeBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HelaService',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(context.l10n.opsPortal,
                      style: TextStyle(
                          fontSize: 10, color: context.themeTextSecondary)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(context.l10n.operationsCore,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: context.themeTextSecondary,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          ...List.generate(entries.length, (i) {
            if (i == 6 &&
                !roleProvider.isSuperAdmin &&
                !roleProvider
                    .hasAdminPermission(AdminPermission.handleSupport)) {
              return const SizedBox.shrink();
            }
            final e = entries[i];
            final active = i == selectedIndex;
            final restricted = isRestricted(i);
            return InkWell(
              onTap: () {
                if (restricted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        i == 4
                            ? context.l10n.sidebarOnlySuperAdmins
                            : context.l10n.sidebarNoPermission,
                      ),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                onSelect(i);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: active
                      ? (context.isDark
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : AppColors.amberTint)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(e.icon,
                      size: 19,
                      color: active
                          ? (context.isDark
                              ? const Color(0xFFF0B44A)
                              : AppColors.amberDark)
                          : (restricted
                              ? context.themeTextSecondary
                                  .withValues(alpha: 0.5)
                              : context.themeTextSecondary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(getLocalizedLabel(i),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color: active
                                ? (context.isDark
                                    ? const Color(0xFFF0B44A)
                                    : AppColors.amberDark)
                                : (restricted
                                    ? context.themeTextSecondary
                                    : context.themeTextPrimary))),
                  ),
                  if (restricted)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_outline,
                          size: 13,
                          color: context.themeTextSecondary
                              .withValues(alpha: 0.6)),
                    ),
                  if (i == 1)
                    StreamBuilder<int>(
                      stream: FirebaseFirestore.instance
                          .collection(FirestorePaths.verificationQueue)
                          .where('status', isEqualTo: 'pending')
                          .snapshots()
                          .map((s) => s.docs.length),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(999)),
                          child: Text('$count',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        );
                      },
                    )
                  else if (i == 6)
                    StreamBuilder<int>(
                      stream: FirebaseFirestore.instance
                          .collection(FirestorePaths.complaints)
                          .where('status', isEqualTo: 'pending')
                          .snapshots()
                          .map((s) => s.docs.length),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(999)),
                          child: Text('$count',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        );
                      },
                    )
                  else if (e.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(e.badge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
            );
          }),
          const Spacer(),
          Divider(indent: 20, endIndent: 20, color: context.themeBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.sidebarColomboCentralHub,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('v2.4',
                        style: TextStyle(
                            fontSize: 10, color: context.themeTextSecondary)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
