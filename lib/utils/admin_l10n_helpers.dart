import 'package:flutter/widgets.dart';

import '../models/admin_user.dart';
import 'l10n_extension.dart';

// admin label helpers

String adminRoleLabel(BuildContext context, AdminRole role) {
  final l10n = context.l10n;
  switch (role) {
    case AdminRole.superAdmin:
      return l10n.roleSuperAdminBadge;
    case AdminRole.opsAdmin:
      return l10n.roleOpsAdminBadge;
    case AdminRole.supportAdmin:
      return l10n.roleSupportAdminBadge;
  }
}

String adminRoleDescription(BuildContext context, AdminRole role) {
  final l10n = context.l10n;
  switch (role) {
    case AdminRole.superAdmin:
      return l10n.adminRoleDescSuper;
    case AdminRole.opsAdmin:
      return l10n.adminRoleDescOps;
    case AdminRole.supportAdmin:
      return l10n.adminRoleDescSupport;
  }
}

String adminPermissionLabel(BuildContext context, AdminPermission p) {
  final l10n = context.l10n;
  switch (p) {
    case AdminPermission.manageAdmins:
      return l10n.permManageAdminsLabel;
    case AdminPermission.verifyNic:
      return l10n.permVerifyNicLabel;
    case AdminPermission.manageCategories:
      return l10n.permManageCategoriesLabel;
    case AdminPermission.broadcastAlerts:
      return l10n.permBroadcastAlertsLabel;
    case AdminPermission.viewFinances:
      return l10n.permViewFinancesLabel;
    case AdminPermission.manageUsers:
      return l10n.permManageUsersLabel;
    case AdminPermission.handleSupport:
      return l10n.permHandleSupportLabel;
  }
}

String adminPermissionDescription(BuildContext context, AdminPermission p) {
  final l10n = context.l10n;
  switch (p) {
    case AdminPermission.manageAdmins:
      return l10n.permManageAdminsDesc;
    case AdminPermission.verifyNic:
      return l10n.permVerifyNicDesc;
    case AdminPermission.manageCategories:
      return l10n.permManageCategoriesDesc;
    case AdminPermission.broadcastAlerts:
      return l10n.permBroadcastAlertsDesc;
    case AdminPermission.viewFinances:
      return l10n.permViewFinancesDesc;
    case AdminPermission.manageUsers:
      return l10n.permManageUsersDesc;
    case AdminPermission.handleSupport:
      return l10n.permHandleSupportDesc;
  }
}

String adminStatusLabel(BuildContext context, AdminStatus s) {
  final l10n = context.l10n;
  switch (s) {
    case AdminStatus.active:
      return l10n.statusActive;
    case AdminStatus.invited:
      return l10n.adminStatusInvited;
    case AdminStatus.suspended:
      return l10n.adminStatusSuspended;
  }
}

// relative time string
String timeAgoL10n(BuildContext context, DateTime? dt, {String fallback = ''}) {
  if (dt == null) return fallback;
  final l10n = context.l10n;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  return l10n.timeDaysAgo(diff.inDays);
}
