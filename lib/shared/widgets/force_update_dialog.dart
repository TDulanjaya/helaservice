import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import 'primary_button.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String updateUrl;

  const ForceUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.updateUrl,
  });

  static void show(
    BuildContext context, {
    required String latestVersion,
    required String updateUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: ForceUpdateDialog(
          latestVersion: latestVersion,
          updateUrl: updateUrl,
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.themeSurface,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.forceUpdateTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.forceUpdateMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.themeTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: context.l10n.updateNowAction,
            onPressed: _openStore,
          ),
        ],
      ),
    );
  }
}
