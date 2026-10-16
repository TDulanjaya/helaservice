import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../shared/widgets/force_update_dialog.dart';

class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  // check minimum app version requirements against cloud config
  Future<void> checkMinimumVersion(BuildContext context) async {
    try {
      int minBuildNumber = 0;
      String latestVersion = '0.1.0';
      String updateUrl =
          'https://play.google.com/store/apps/details?id=com.helaservice.app';

      // 1. Check Firebase Remote Config
      try {
        final rc = FirebaseRemoteConfig.instance;
        final rcMin = rc.getInt('min_build_number');
        if (rcMin > 0) minBuildNumber = rcMin;
        final rcMinStr = rc.getString('min_version');
        final rcParsed = int.tryParse(rcMinStr);
        if (rcParsed != null && rcParsed > minBuildNumber) {
          minBuildNumber = rcParsed;
        }
        final rcLatest = rc.getString('latest_version');
        if (rcLatest.isNotEmpty) latestVersion = rcLatest;
        final rcUrl = rc.getString('update_url');
        if (rcUrl.isNotEmpty) updateUrl = rcUrl;
      } catch (_) {}

      // 2. Check Firestore fallback
      try {
        final doc = await FirebaseFirestore.instance
            .collection('appConfig')
            .doc('version')
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final fsMin = data['minBuildNumber'] as int? ?? 0;
          if (fsMin > minBuildNumber) {
            minBuildNumber = fsMin;
          }
          if (data['latestVersion'] != null) {
            latestVersion = data['latestVersion'] as String;
          }
          if (data['updateUrl'] != null) {
            updateUrl = data['updateUrl'] as String;
          }
        }
      } catch (_) {}

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
