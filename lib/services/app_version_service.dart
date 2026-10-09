import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../shared/widgets/force_update_dialog.dart';

class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  // check minimum app version requirements against cloud config
  Future<void> checkMinimumVersion(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appConfig')
          .doc('version')
          .get();

      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final minBuildNumber = data['minBuildNumber'] as int? ?? 0;
      final latestVersion = data['latestVersion'] as String? ?? '1.0.0';
      final updateUrl = data['updateUrl'] as String? ??
          'https://play.google.com/store/apps/details?id=com.helaservice.app';

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (currentBuild > 0 && currentBuild < minBuildNumber) {
        if (context.mounted) {
          ForceUpdateDialog.show(
            context,
            latestVersion: latestVersion,
            updateUrl: updateUrl,
          );
        }
      }
    } catch (_) {
      // gracefully continue if network or config document is unavailable
    }
  }
}
