import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/localization.dart';
import '../services/theme_service.dart';
import '../widgets/choice_sheet.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.returnToLogin = false});

  final bool returnToLogin;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  List<_OnboardingPage> get _pages => [
    _OnboardingPage(
      icon: Icons.meeting_room_rounded,
      title: LocalizationService.get('onboarding_room_title'),
      body: LocalizationService.get('onboarding_room_body'),
    ),
    _OnboardingPage(
      icon: Icons.enhanced_encryption_rounded,
      title: LocalizationService.get('onboarding_e2ee_title'),
      body: LocalizationService.get('onboarding_e2ee_body'),
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: LocalizationService.get('onboarding_realtime_title'),
      body: LocalizationService.get('onboarding_realtime_body'),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);

    if (!mounted) return;
    if (widget.returnToLogin) {
      Navigator.pop(context);
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: LocalizationService.currentLang,
      builder: (context, lang, child) {
        final pages = _pages;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: AppThemeService.isDark ? 'Light mode' : 'Dark mode',
                onPressed: AppThemeService.toggle,
                icon: Icon(
                  AppThemeService.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _buildLanguageButton(lang),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const [Color(0xFF0E1117), Color(0xFF121826)]
                          : const [Color(0xFFF6F8FB), Color(0xFFFFFFFF)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _finish,
                          child: Text(
                            LocalizationService.get('onboarding_skip'),
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.54),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: pages.length,
                          onPageChanged: (value) =>
                              setState(() => _page = value),
                          itemBuilder: (context, index) =>
                              _buildPage(pages[index]),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < pages.length; i++)
                            Container(
                              width: i == _page ? 22 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? scheme.primary
                                    : scheme.onSurface.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _page == pages.length - 1
                              ? LocalizationService.get('onboarding_start')
                              : LocalizationService.get('onboarding_next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(page.icon, size: 54, color: scheme.primary),
            ),
            const SizedBox(height: 36),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(AppLang lang) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final label = lang == AppLang.ko
        ? LocalizationService.get('language_ko')
        : LocalizationService.get('language_en');
    return InkWell(
      onTap: () => _showLanguageSheet(lang),
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

  Future<void> _showLanguageSheet(AppLang lang) async {
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

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
