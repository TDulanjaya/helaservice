import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';

class PermissionUtils {
  // location permission sheet
  static Future<bool> requestLocationWithRationale(BuildContext context) async {
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.always ||
        current == LocationPermission.whileInUse) {
      return true;
    }

    if (current == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showSettingsPrompt(
          context,
          title: context.l10n.permissionLocationNeeded,
          description: context.l10n.permissionLocationPermanentlyDisabled,
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    // show custom rationale sheet
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionSheet(
        icon: Icons.location_on_rounded,
        iconColor: AppColors.primary,
        title: context.l10n.permissionLocationTitle,
        description: context.l10n.permissionLocationDesc,
        bulletPoints: [
          context.l10n.permissionLocationBullet1,
          context.l10n.permissionLocationBullet2,
          context.l10n.permissionLocationBullet3,
        ],
        primaryButtonText: context.l10n.permissionAllowAndContinue,
        secondaryButtonText: context.l10n.permissionSelectDistrictManually,
      ),
    );

    if (agreed != true) return false;

    final requested = await Geolocator.requestPermission();
    return requested == LocationPermission.always ||
        requested == LocationPermission.whileInUse;
  }

  // camera permission sheet
  static Future<bool> requestCameraWithRationale(
    BuildContext context, {
    String? title,
    String? description,
  }) async {
    final status = await ph.Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsPrompt(
          context,
          title: title ?? context.l10n.permissionCameraTitle,
          description: context.l10n.permissionCameraPermanentlyDisabled,
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionSheet(
        icon: Icons.camera_alt_rounded,
        iconColor: AppColors.primary,
        title: title ?? context.l10n.permissionCameraTitle,
        description: description ?? context.l10n.permissionCameraDesc,
        bulletPoints: [
          context.l10n.permissionCameraBullet1,
          context.l10n.permissionCameraBullet2,
          context.l10n.permissionCameraBullet3,
        ],
        primaryButtonText: context.l10n.permissionOpenCamera,
        secondaryButtonText: context.l10n.cancel,
      ),
    );

    if (agreed != true) return false;

    final result = await ph.Permission.camera.request();
    if (result.isPermanentlyDenied && context.mounted) {
      _showSettingsPrompt(
        context,
        title: title ?? context.l10n.permissionCameraTitle,
        description: context.l10n.permissionCameraDisabled,
      );
      return false;
    }
    return result.isGranted;
  }

  // gallery permission sheet
  static Future<bool> requestGalleryWithRationale(
    BuildContext context, {
    String? title,
    String? description,
  }) async {
    final photosStatus = await ph.Permission.photos.status;
    final storageStatus = await ph.Permission.storage.status;
    if (photosStatus.isGranted || storageStatus.isGranted) return true;

    if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsPrompt(
          context,
          title: title ?? context.l10n.permissionGalleryTitle,
          description: context.l10n.permissionGalleryPermanentlyDisabled,
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionSheet(
        icon: Icons.photo_library_rounded,
        iconColor: AppColors.primary,
        title: title ?? context.l10n.permissionGalleryTitle,
        description: description ?? context.l10n.permissionGalleryDesc,
        bulletPoints: [
          context.l10n.permissionGalleryBullet1,
          context.l10n.permissionGalleryBullet2,
          context.l10n.permissionGalleryBullet3,
        ],
        primaryButtonText: context.l10n.permissionChoosePhotos,
        secondaryButtonText: context.l10n.cancel,
      ),
    );

    if (agreed != true) return false;

    // request photos or storage
    final statuses =
        await [ph.Permission.photos, ph.Permission.storage].request();
    final isAllowed = statuses[ph.Permission.photos]?.isGranted == true ||
        statuses[ph.Permission.storage]?.isGranted == true;

    if (!isAllowed &&
        (statuses[ph.Permission.photos]?.isPermanentlyDenied == true ||
            statuses[ph.Permission.storage]?.isPermanentlyDenied == true) &&
        context.mounted) {
      _showSettingsPrompt(
        context,
        title: title ?? context.l10n.permissionGalleryTitle,
        description: context.l10n.permissionGalleryDisabled,
      );
    }

    return isAllowed;
  }

  // notification permission sheet
  static Future<bool> requestNotificationWithRationale(
    BuildContext context, {
    String? title,
    String? description,
  }) async {
    final status = await ph.Permission.notification.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsPrompt(
          context,
          title: title ?? context.l10n.permissionNotificationNeeded,
          description: context.l10n.permissionNotificationPermanentlyDisabled,
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionSheet(
        icon: Icons.notifications_active_rounded,
        iconColor: AppColors.primary,
        title: title ?? context.l10n.permissionNotificationTitle,
        description: description ?? context.l10n.permissionNotificationDesc,
        bulletPoints: [
          context.l10n.permissionNotificationBullet1,
          context.l10n.permissionNotificationBullet2,
          context.l10n.permissionNotificationBullet3,
        ],
        primaryButtonText: context.l10n.permissionEnableNotifications,
        secondaryButtonText: context.l10n.permissionNotNow,
      ),
    );

    if (agreed != true) return false;

    final result = await ph.Permission.notification.request();
    return result.isGranted;
  }

  // check notifications on login
  static Future<void> checkAndPromptInitialPermissions(
      BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('has_prompted_notifications') ?? false;
      if (!hasPrompted && context.mounted) {
        await prefs.setBool('has_prompted_notifications', true);
        if (context.mounted) {
          await requestNotificationWithRationale(context);
        }
      }
    } catch (e) {
      debugPrint('[PermissionUtils] Initial permission check error: $e');
    }
  }

  // open system settings prompt
  static void _showSettingsPrompt(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(description,
            style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ph.openAppSettings();
            },
            child: Text(context.l10n.openSettings),
          ),
        ],
      ),
    );
  }
}

class _PermissionSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> bulletPoints;
  final String primaryButtonText;
  final String secondaryButtonText;

  const _PermissionSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.bulletPoints,
    required this.primaryButtonText,
    required this.secondaryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.themeTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                children: bulletPoints.map((bp) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bp,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                primaryButtonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.themeTextSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                secondaryButtonText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
