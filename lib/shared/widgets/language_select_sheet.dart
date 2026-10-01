import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../state/locale_provider.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';

class LanguageSelectSheet extends StatelessWidget {
  const LanguageSelectSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const LanguageSelectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = pv.Provider.of<LocaleProvider>(context);
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final currentCode = localeProvider.languageCode;
    final userId = roleProvider.currentUser?.id;

    final languages = [
      {
        'code': 'en',
        'name': 'English',
        'native': 'English',
        'subtitle': 'Default system language',
      },
      {
        'code': 'si',
        'name': 'Sinhala',
        'native': 'සිංහල',
        'subtitle': 'ශ්‍රී ලංකා දේශීය භාෂාව',
      },
      {
        'code': 'ta',
        'name': 'Tamil',
        'native': 'தமிழ்',
        'subtitle': 'இலங்கை தமிழ் மொழி',
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Language / භාෂාව / மொழி',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose your primary display language',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = currentCode == lang['code'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : context.themeBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : context.themeBorder.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lang['code']!.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.primary
                            : context.themeTextPrimary,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        lang['native']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${lang['name']})',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    lang['subtitle']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 22)
                      : const Icon(Icons.circle_outlined,
                          color: AppColors.outline, size: 20),
                  onTap: () async {
                    await localeProvider.setLocale(
                      Locale(lang['code']!),
                      userId: userId,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language switched to ${lang['native']} (${lang['name']})',
                          ),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
