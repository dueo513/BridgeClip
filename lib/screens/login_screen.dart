import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/crypto_service.dart';
import '../services/database_service.dart';
import '../services/localization.dart';
import '../services/theme_service.dart';
import '../state/global_state.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isCreateMode = true;

  @override
  void initState() {
    super.initState();
    _generateRoomId();
    GlobalState.joinRoomNotifier.addListener(_applyPendingJoinRoom);
    _loadInitialJoinLink();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyPendingJoinRoom(),
    );
  }

  Future<void> _loadInitialJoinLink() async {
    try {
      final uri = await AppLinks().getInitialLink();
      _applyJoinUri(uri);
    } catch (e) {
      debugPrint('Initial join link read failed: $e');
    }
  }

  void _applyJoinUri(Uri? uri) {
    if (uri == null) return;
    final isJoinLink =
        (uri.scheme == 'bridgeclip' || uri.scheme == 'appclip') &&
        uri.host == 'join';
    if (!isJoinLink) return;

    final roomId = uri.queryParameters['room'];
    if (roomId == null || roomId.trim().isEmpty) return;
    _applyJoinRoom(roomId);
  }

  void _applyPendingJoinRoom() {
    final roomId = GlobalState.pendingJoinRoomId;
    if (roomId == null || roomId.trim().isEmpty || !mounted) return;
    GlobalState.pendingJoinRoomId = null;
    _applyJoinRoom(roomId);
  }

  void _applyJoinRoom(String roomId) {
    if (!mounted) return;
    setState(() {
      _isCreateMode = false;
      _roomIdController.text = roomId.trim();
    });
  }

  void _generateRoomId() {
    _roomIdController.text = DatabaseService.generateRoomId();
  }

  Future<void> _connect() async {
    final rawRoomId = _roomIdController.text.trim();
    final roomId = _isCreateMode ? rawRoomId.toUpperCase() : rawRoomId;
    final roomPassword = _passwordController.text.trim();

    if (roomId.isEmpty || roomPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.get('login_err_empty'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await CryptoService.instance.init(roomPassword);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.get('login_err_key'))),
      );
      debugPrint('Crypto init failed: $e');
      return;
    }

    final db = DatabaseService(roomId: roomId);
    try {
      if (_isCreateMode) {
        await db.createRoomRegistry();
      } else {
        final exists = await db.roomExists();
        if (!exists) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.get('room_not_found'))),
          );
          return;
        }
        await db.touchRoomRegistry();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCreateMode
                ? LocalizationService.get('room_create_failed')
                : LocalizationService.get('room_join_failed'),
          ),
        ),
      );
      debugPrint('Room connection failed: $e');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roomId', roomId);
    await prefs.setString('roomPassword', roomPassword);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ClipboardHome(roomId: roomId)),
    );
  }

  @override
  void dispose() {
    GlobalState.joinRoomNotifier.removeListener(_applyPendingJoinRoom);
    _roomIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: LocalizationService.currentLang,
      builder: (context, lang, child) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppLang>(
                    value: lang,
                    dropdownColor: scheme.surface,
                    icon: Icon(Icons.language, color: scheme.primary),
                    items: [
                      DropdownMenuItem(
                        value: AppLang.ko,
                        child: Text(
                          LocalizationService.get('language_ko'),
                          style: TextStyle(color: scheme.onSurface),
                        ),
                      ),
                      DropdownMenuItem(
                        value: AppLang.en,
                        child: Text(
                          LocalizationService.get('language_en'),
                          style: TextStyle(color: scheme.onSurface),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        LocalizationService.setLanguage(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              Color(0xFF0E1117),
                              Color(0xFF121826),
                              Color(0xFF0E1117),
                            ]
                          : const [
                              Color(0xFFF6F8FB),
                              Color(0xFFEFF5FF),
                              Color(0xFFF8FAFC),
                            ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(
                              Icons.cloud_sync_rounded,
                              size: 58,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'BridgeClip',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService.get('login_title'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              color: scheme.onSurface.withValues(alpha: 0.58),
                            ),
                          ),
                          const SizedBox(height: 34),
                          _buildLoginCard(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 17,
                                color: scheme.secondary.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  LocalizationService.get('login_info'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingScreen(
                                    returnToLogin: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.help_outline, size: 18),
                            label: Text(
                              LocalizationService.get('onboarding_help'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(LocalizationService.get('create_room')),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.login_rounded),
                label: Text(LocalizationService.get('join_room')),
              ),
            ],
            selected: {_isCreateMode},
            onSelectionChanged: _isLoading
                ? null
                : (values) {
                    final next = values.first;
                    setState(() {
                      _isCreateMode = next;
                      if (next) _generateRoomId();
                    });
                  },
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.get(
              _isCreateMode ? 'create_room_desc' : 'join_room_desc',
            ),
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.58),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          _buildFieldLabel(LocalizationService.get('room_id_label')),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _roomIdController,
            hint: LocalizationService.get('room_id_hint'),
            icon: Icons.vpn_key_rounded,
            readOnly: _isCreateMode,
            trailing: _isCreateMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: IconButton(
                          tooltip: LocalizationService.get('copy'),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _roomIdController.text),
                            );
                          },
                          icon: Icon(
                            Icons.copy_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.48),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: IconButton(
                          tooltip: LocalizationService.get(
                            'btn_regenerate_room',
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: _generateRoomId,
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            onSubmitted: (_) => _connect(),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel(LocalizationService.get('password_label')),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            hint: LocalizationService.get('password_hint'),
            icon: Icons.lock_rounded,
            obscureText: true,
            onSubmitted: (_) => _connect(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _connect,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    LocalizationService.get(
                      _isCreateMode ? 'btn_create_room' : 'btn_join_room',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.72),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onSubmitted,
    bool obscureText = false,
    bool readOnly = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: readOnly ? 15.5 : 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.36),
          fontSize: 15,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.035),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIcon: Icon(icon, color: scheme.primary),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: trailing,
        suffixIconConstraints: trailing == null
            ? null
            : const BoxConstraints(minWidth: 76, maxWidth: 84),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
