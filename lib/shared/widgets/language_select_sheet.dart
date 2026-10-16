import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../state/locale_provider.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

class LanguageSelectSheet extends StatelessWidget {
  const LanguageSelectSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        'name': context.l10n.languageEnglish,
        'native': 'English',
        'subtitle': context.l10n.custDefaultSystemLanguage,
      },
      {
        'code': 'si',
        'name': context.l10n.languageSinhala,
        'native': 'සිංහල',
        'subtitle': 'ශ්‍රී ලංකා දේශීය භාෂාව',
      },
      {
        'code': 'ta',
        'name': context.l10n.languageTamil,
        'native': 'தமிழ்',
        'subtitle': 'இலங்கை தமிழ் மொழி',
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.themeInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.chooseDisplayLanguage,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: context.themeTextSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...languages.map((lang) {
              final isSelected = currentCode == lang['code'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? context.themeAmberTint : context.themeSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : context.themeBorder,
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : context.themeSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lang['code']!.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color:
                            isSelected ? AppColors.primary : context.themeInk,
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
                          color: context.themeInk,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${lang['name']})',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    lang['subtitle']!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: context.themeMuted.withValues(alpha: 0.5),
                          size: 20,
                        ),
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
                            '${context.l10n.languageSwitchedTo} ${lang['native']} (${lang['name']})',
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
