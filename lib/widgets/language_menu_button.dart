import 'package:flutter/material.dart';

import '../services/localization.dart';
import 'choice_sheet.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, required this.lang});

  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final label = lang == AppLang.ko
        ? LocalizationService.get('language_ko')
        : LocalizationService.get('language_en');

    return InkWell(
      onTap: () => _showLanguageSheet(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.56),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selected = await showModalBottomSheet<AppLang>(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) => ChoiceSheet<AppLang>(
        title: LocalizationService.get('language_title'),
        value: lang,
        options: const [AppLang.ko, AppLang.en],
        labelFor: (value) => value == AppLang.ko
            ? LocalizationService.get('language_ko')
            : LocalizationService.get('language_en'),
        iconFor: (_) => Icons.language_rounded,
        primaryColor: scheme.primary,
        surfaceColor: scheme.surface,
        softFillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.035),
        borderColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        textColor: scheme.onSurface,
        mutedTextColor: scheme.onSurface.withValues(alpha: 0.56),
      ),
    );

    if (selected != null) {
      await LocalizationService.setLanguage(selected);
    }
  }
}
