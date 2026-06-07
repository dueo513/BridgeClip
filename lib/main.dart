import 'dart:async';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_links/app_links.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'firebase_options.dart';
import 'models/clipboard_item.dart';
import 'models/device_info.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_lock_service.dart';
import 'services/clipboard_upload_coordinator.dart';
import 'services/crypto_service.dart';
import 'services/database_service.dart';
import 'services/desktop_shell_service.dart';
import 'services/device_identity_service.dart';
import 'services/localization.dart';
import 'services/platform_service.dart';
import 'services/theme_service.dart';
import 'state/global_state.dart';
import 'widgets/app_lock_dialogs.dart';
import 'widgets/auto_delete_timer_dialog.dart';
import 'widgets/choice_sheet.dart';
import 'widgets/clipboard_body.dart';
import 'widgets/connect_device_sheet.dart';
import 'widgets/device_management_body.dart';
import 'widgets/locked_scaffold.dart';
import 'widgets/top_icon_button.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (response.actionId != 'copy' && response.actionId != 'select_copy') return;

  final encryptedText = response.payload;
  if (encryptedText == null || encryptedText.isEmpty) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final roomPassword = prefs.getString('roomPassword');
    if (roomPassword == null || roomPassword.isEmpty) return;

    await CryptoService.instance.init(roomPassword);
    final clearText = await CryptoService.instance.decrypt(encryptedText);
    final encoded = Uri.encodeComponent(clearText);
    final host = response.actionId == 'select_copy' ? 'select_copy' : 'copy';
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: 'copysync://$host?text=$encoded',
      flags: <int>[268435456],
    );
    await intent.launch();
  } catch (e) {
    debugPrint('Notification copy failed: $e');
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('isNotificationEnabled') ?? true;
  if (!isEnabled) return;

  final title =
      message.data['title'] ?? LocalizationService.get('notification_title');
  final body =
      message.data['body'] ?? LocalizationService.get('notification_body');
  final text = message.data['text'] ?? '';

  const androidDetails = AndroidNotificationDetails(
    'clipboard_channel',
    'Clipboard notifications',
    importance: Importance.max,
    priority: Priority.high,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction('copy', 'Copy', showsUserInterface: true),
      AndroidNotificationAction(
        'select_copy',
        'Select copy',
        showsUserInterface: true,
      ),
    ],
  );

  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: text,
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data.isNotEmpty) {
    await _showLocalNotification(message);
  }
}

void _handleLocalNotification(NotificationResponse response) async {
  if (response.actionId != 'copy' && response.actionId != 'select_copy') return;

  final encryptedText = response.payload;
  if (encryptedText == null || encryptedText.isEmpty) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final roomPassword = prefs.getString('roomPassword');
    if (roomPassword == null || roomPassword.isEmpty) return;

    await CryptoService.instance.init(roomPassword);
    final clearText = await CryptoService.instance.decrypt(encryptedText);
    if (response.actionId == 'copy') {
      GlobalState.pendingCopyText = clearText;
      GlobalState.copyNotifier.value = DateTime.now().millisecondsSinceEpoch
          .toString();
    } else {
      GlobalState.pendingSelectCopyText = clearText;
      GlobalState.selectCopyNotifier.value = DateTime.now()
          .millisecondsSinceEpoch
          .toString();
    }
  } catch (e) {
    debugPrint('Foreground notification copy failed: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService.init();
  await AppThemeService.init();
  if (!Platform.isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (PlatformService.isMobile) {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotification,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final launchDetails = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        response != null) {
      _handleLocalNotification(response);
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final roomId = prefs.getString('roomId');
  final roomPassword = prefs.getString('roomPassword');
  final onboardingSeen = prefs.getBool('onboardingSeen') ?? false;

  if (roomId != null && roomPassword != null) {
    try {
      await CryptoService.instance.init(roomPassword);
      await DatabaseService(roomId: roomId).ensureRoomRegistry();
    } catch (e) {
      debugPrint('Stored room could not be prepared: $e');
    }
  }

  await DesktopShellService.setup();

  runApp(
    ClipboardSyncApp(
      initialRoomId: roomId,
      initialRoomPassword: roomPassword,
      initialShowOnboarding: roomId == null && !onboardingSeen,
    ),
  );
}

class ClipboardSyncApp extends StatelessWidget {
  const ClipboardSyncApp({
    super.key,
    this.initialRoomId,
    this.initialRoomPassword,
    this.initialShowOnboarding = false,
  });

  final String? initialRoomId;
  final String? initialRoomPassword;
  final bool initialShowOnboarding;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: LocalizationService.currentLang,
      builder: (context, lang, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeService.themeMode,
          builder: (context, themeMode, child) {
            return MaterialApp(
              title: 'BridgeClip',
              theme: BridgeClipTheme.light(),
              darkTheme: BridgeClipTheme.dark(),
              themeMode: themeMode,
              home: initialRoomId == null || initialRoomPassword == null
                  ? (initialShowOnboarding
                        ? const OnboardingScreen()
                        : const LoginScreen())
                  : ClipboardHome(roomId: initialRoomId!),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}

class ClipboardHome extends StatefulWidget {
  const ClipboardHome({super.key, required this.roomId});

  final String roomId;

  @override
  State<ClipboardHome> createState() => _ClipboardHomeState();
}

class _ClipboardHomeState extends State<ClipboardHome>
    with WidgetsBindingObserver, WindowListener, ClipboardListener {
  static const quickSyncChannel = MethodChannel('com.antigravity/quick_sync');
  static const clipboardGuardChannel = MethodChannel(
    'com.antigravity/clipboard_guard',
  );

  late final DatabaseService _db;
  late final AppLinks _appLinks;
  late final ClipboardUploadCoordinator _uploadCoordinator;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _unlockPinController = TextEditingController();
  final List<String> _optimisticDeletedIds = [];
  final List<int> _appWrittenClipboardSequences = [];
  String _lastCopiedByApp = '';
  Timer? _clipboardBackupTimer;
  StreamSubscription<List<ClipboardItem>>? _desktopSyncSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  String? _currentDeviceId;
  String _currentDeviceName = PlatformService.defaultDeviceName();
  bool _isArchiveTab = false;
  bool _isDeviceManagementTab = false;
  bool _isNotificationEnabled = true;
  bool _isAppLockEnabled = false;
  bool _isLocked = false;
  bool? _launchAtStartupEnabled;
  String _searchQuery = '';
  String _deviceFilter = 'all';
  String _timeFilter = 'all';
  int _autoDeleteMinutes = 0;
  bool _isWritingClipboardFromApp = false;

  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _surfaceColor => Theme.of(context).colorScheme.surface;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _mutedTextColor => _textColor.withValues(alpha: 0.58);
  Color get _softFillColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.035);
  Color get _borderColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.07);

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(roomId: widget.roomId);
    _uploadCoordinator = ClipboardUploadCoordinator(_uploadLocalClipboardText);

    WidgetsBinding.instance.addObserver(this);
    _initClipboardState();
    _initAppLinks();
    _loadExpireSettings();
    _loadNotificationSettings();
    _loadAppLockSettings();
    _loadLaunchAtStartupStatus();
    _registerCurrentDevice();
    _checkQuickSync();
    _setupFcm();
    _registerNotificationCopyHandlers();

    if (PlatformService.isDesktop) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
      try {
        clipboardWatcher.addListener(this);
        clipboardWatcher.start();
      } catch (e) {
        debugPrint('Clipboard watcher start failed: $e');
      }

      _clipboardBackupTimer = Timer.periodic(
        const Duration(milliseconds: 300),
        (_) => _checkClipboardPeriodic(),
      );
      _desktopSyncSubscription = _db.clipboardStream.listen((items) async {
        if (items.isEmpty) return;
        final latest = items.first;
        final currentDeviceId =
            _currentDeviceId ?? await DeviceIdentityService.deviceId();
        final currentDeviceName = await DeviceIdentityService.deviceName();
        final isFromCurrentDevice = latest.deviceId != null
            ? latest.deviceId == currentDeviceId
            : latest.deviceName == currentDeviceName;
        if (!isFromCurrentDevice) {
          if (_lastCopiedByApp != latest.content) {
            _copyToLocalClipboard(latest.content);
          }
        }
      });
    }
  }

  @override
  void onClipboardChanged() {
    if (!PlatformService.isDesktop) return;
    _readAndQueueLocalClipboard('watcher');
  }

  void _registerNotificationCopyHandlers() {
    GlobalState.selectCopyNotifier.addListener(() {
      final text = GlobalState.pendingSelectCopyText;
      if (text == null || !mounted) return;
      GlobalState.pendingSelectCopyText = null;
      _showSelectCopyDialog(text);
    });

    GlobalState.copyNotifier.addListener(() {
      final text = GlobalState.pendingCopyText;
      if (text == null || !mounted) return;
      GlobalState.pendingCopyText = null;
      _executeSafeCopy(text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectText = GlobalState.pendingSelectCopyText;
      if (selectText != null && mounted) {
        GlobalState.pendingSelectCopyText = null;
        _showSelectCopyDialog(selectText);
      }

      final copyText = GlobalState.pendingCopyText;
      if (copyText != null && mounted) {
        GlobalState.pendingCopyText = null;
        _executeSafeCopy(copyText);
      }
    });
  }

  Future<void> _executeSafeCopy(String text) async {
    var success = false;
    for (var attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        await Clipboard.setData(ClipboardData(text: text));
        success = true;
        break;
      } catch (_) {
        // Android notification actions may need a short focus handoff.
      }
    }

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.get('copied_now_toast'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(milliseconds: 800),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
    }

    SystemNavigator.pop();
  }

  Future<void> _initClipboardState() async {
    try {
      final initial = await Clipboard.getData(Clipboard.kTextPlain);
      _lastCopiedByApp = initial?.text ?? '';
    } catch (e) {
      debugPrint('Init clipboard fetch error: $e');
    }
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleAppLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleAppLink(uri);
    });
  }

  void _handleAppLink(Uri uri) {
    final isJoinLink =
        (uri.scheme == 'bridgeclip' || uri.scheme == 'appclip') &&
        uri.host == 'join';
    if (isJoinLink) {
      final room = uri.queryParameters['room'];
      if (room != null && room.trim().isNotEmpty) {
        GlobalState.pendingJoinRoomId = room.trim();
        GlobalState.joinRoomNotifier.value = DateTime.now()
            .millisecondsSinceEpoch
            .toString();
      }
      return;
    }
    if (uri.scheme != 'copysync' && uri.scheme != 'appclip') return;

    final text = uri.queryParameters['text'];
    if (text == null || text.isEmpty) return;

    if (uri.host == 'copy') {
      _copyToLocalClipboard(text);
    } else if (uri.host == 'select_copy') {
      _showSelectCopyDialog(text);
    }
  }

  Future<void> _loadExpireSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoDeleteMinutes = prefs.getInt('autoDeleteMinutes') ?? 0;
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
    });
  }

  Future<void> _loadAppLockSettings() async {
    final isEnabled = await AppLockService.isEnabled();
    if (!mounted) return;
    setState(() {
      _isAppLockEnabled = isEnabled;
      _isLocked = isEnabled;
    });
  }

  Future<void> _loadLaunchAtStartupStatus() async {
    if (!PlatformService.isDesktop) return;

    try {
      final isEnabled = await launchAtStartup.isEnabled();
      if (!mounted) return;
      setState(() => _launchAtStartupEnabled = isEnabled);
    } catch (e) {
      debugPrint('Launch-at-startup status check failed: $e');
    }
  }

  void _lockApp() {
    if (!_isAppLockEnabled || _isLocked || !mounted) return;
    _unlockPinController.clear();
    setState(() => _isLocked = true);
  }

  Future<void> _unlockApp() async {
    final pin = _unlockPinController.text.trim();
    if (pin.isEmpty) return;

    final isValid = await AppLockService.verify(pin);
    if (!mounted) return;

    if (isValid) {
      _unlockPinController.clear();
      setState(() => _isLocked = false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.get('app_lock_wrong_pin')),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _registerCurrentDevice() async {
    final deviceId = await DeviceIdentityService.deviceId();
    final deviceName = await DeviceIdentityService.deviceName();
    final platform = DeviceIdentityService.platformName();
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('isNotificationEnabled') ?? true;

    if (!mounted) return;
    setState(() {
      _currentDeviceId = deviceId;
      _currentDeviceName = deviceName;
    });

    try {
      await _db.registerDevice(
        DeviceInfo(
          id: deviceId,
          deviceName: deviceName,
          platform: platform,
          notificationsEnabled: notificationsEnabled,
        ),
      );
    } catch (e) {
      debugPrint('Device register failed: $e');
    }
  }

  Future<void> _toggleNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_isNotificationEnabled;
    await prefs.setBool('isNotificationEnabled', newValue);
    try {
      await _db.setCurrentDeviceNotifications(newValue);
    } catch (e) {
      debugPrint('Notification preference sync failed: $e');
    }

    if (!mounted) return;
    setState(() => _isNotificationEnabled = newValue);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newValue
              ? LocalizationService.get('notification_enabled')
              : LocalizationService.get('notification_disabled'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Future<void> _setupFcm() async {
    if (!PlatformService.isMobile) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final deviceId = await DeviceIdentityService.deviceId();
      final deviceName = await DeviceIdentityService.deviceName();
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('isNotificationEnabled') ?? _isNotificationEnabled;
      final token = await messaging.getToken();
      if (token != null) {
        await _db.saveFcmToken(
          deviceId,
          deviceName,
          token,
          platform: PlatformService.platformName(),
          notificationsEnabled: notificationsEnabled,
        );
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final refreshedDeviceId = await DeviceIdentityService.deviceId();
        final refreshedDeviceName = await DeviceIdentityService.deviceName();
        _db.saveFcmToken(
          refreshedDeviceId,
          refreshedDeviceName,
          newToken,
          platform: PlatformService.platformName(),
          notificationsEnabled:
              prefs.getBool('isNotificationEnabled') ?? _isNotificationEnabled,
        );
      });

      FirebaseMessaging.onMessage.listen((message) async {
        if (message.data.isNotEmpty) {
          await _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_copyFromRemoteMessage);

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        await _copyFromRemoteMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM setup failed: $e');
    }
  }

  Future<void> _copyFromRemoteMessage(RemoteMessage message) async {
    final text = message.data['text'];
    if (text == null || text.toString().isEmpty) return;

    final clearText = await CryptoService.instance.decrypt(text.toString());
    _copyToLocalClipboard(clearText);
  }

  Future<void> _checkQuickSync() async {
    if (!Platform.isAndroid) return;

    try {
      final isQuickSync =
          await quickSyncChannel.invokeMethod<bool>('checkQuickSync') ?? false;
      if (!isQuickSync) return;

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null && text.trim().isNotEmpty) {
        await _uploadLocalClipboardText(text);
        await _db.waitForPendingWrites().timeout(const Duration(seconds: 20));
      }
      SystemNavigator.pop();
    } catch (e) {
      debugPrint('Quick sync failed: $e');
    }
  }

  Future<void> _checkClipboardPeriodic() async {
    await _readAndQueueLocalClipboard('backup-poll');
  }

  Future<void> _readAndQueueLocalClipboard(String source) async {
    try {
      final isAppWrittenSequence =
          _isWritingClipboardFromApp ||
          await _isCurrentClipboardSequenceAppWritten();
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) return;
      if (isAppWrittenSequence) {
        _lastCopiedByApp = text;
        debugPrint('Clipboard app-written sequence ignored from $source.');
        return;
      }
      if (_lastCopiedByApp == text) return;

      _lastCopiedByApp = text;
      final queued = _uploadCoordinator.enqueue(text);
      if (queued) {
        debugPrint('Clipboard upload queued from $source.');
      }
    } catch (e) {
      debugPrint('Clipboard read failed: $e');
    }
  }

  Future<int?> _currentClipboardSequenceNumber() async {
    if (!Platform.isWindows) return null;

    try {
      final sequence = await clipboardGuardChannel.invokeMethod<Object?>(
        'getClipboardSequenceNumber',
      );
      return switch (sequence) {
        int value => value,
        num value => value.toInt(),
        _ => null,
      };
    } catch (e) {
      debugPrint('Clipboard sequence lookup failed: $e');
      return null;
    }
  }

  Future<void> _rememberAppClipboardWriteSequence() async {
    final sequence = await _currentClipboardSequenceNumber();
    if (sequence == null) return;

    _appWrittenClipboardSequences.add(sequence);
    if (_appWrittenClipboardSequences.length > 16) {
      _appWrittenClipboardSequences.removeRange(
        0,
        _appWrittenClipboardSequences.length - 16,
      );
    }
  }

  Future<bool> _isCurrentClipboardSequenceAppWritten() async {
    final sequence = await _currentClipboardSequenceNumber();
    if (sequence == null) return false;

    final index = _appWrittenClipboardSequences.indexOf(sequence);
    if (index == -1) return false;

    _appWrittenClipboardSequences.removeAt(index);
    return true;
  }

  Future<void> _uploadLocalClipboardText(String text) async {
    await _db.addClipboardItem(
      text,
      await DeviceIdentityService.deviceName(),
      PlatformService.platformName(),
    );
  }

  void _copyToLocalClipboard(String text) async {
    _lastCopiedByApp = text;
    _isWritingClipboardFromApp = true;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      await _rememberAppClipboardWriteSequence();
    } finally {
      _isWritingClipboardFromApp = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocalizationService.get('copied_toast'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _showSelectCopyDialog(String text) {
    if (!mounted) return;
    final controller = TextEditingController(text: text);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            LocalizationService.get('select_copy_title'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withValues(alpha: 0.2),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                LocalizationService.get('close'),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                _copyToLocalClipboard(controller.text);
                Navigator.pop(context);
              },
              child: Text(
                LocalizationService.get('copy_selected'),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
    await prefs.remove('roomPassword');
    CryptoService.instance.clear();

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _removeCurrentDeviceAndLogout() async {
    final deviceId = _currentDeviceId ?? await DeviceIdentityService.deviceId();
    try {
      await _db.deleteDevice(deviceId);
    } catch (e) {
      debugPrint('Current device delete failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
    await prefs.remove('roomPassword');
    await DeviceIdentityService.clearDeviceIdentity();
    CryptoService.instance.clear();

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showRenameDeviceDialog() {
    final controller = TextEditingController(text: _currentDeviceName);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          LocalizationService.get('device_rename_title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: LocalizationService.get('device_name_hint'),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LocalizationService.get('cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final navigator = Navigator.of(context);
              await _db.renameCurrentDevice(newName);
              if (!mounted) return;
              setState(() => _currentDeviceName = newName);
              navigator.pop();
            },
            child: Text(
              LocalizationService.get('ok'),
              style: const TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppLockDialog() {
    AppLockDialogs.show(
      context: context,
      isEnabled: _isAppLockEnabled,
      onLockNow: _lockApp,
      onEnabled: () {
        if (!mounted) return;
        setState(() {
          _isAppLockEnabled = true;
          _isLocked = false;
        });
      },
      onDisabled: () {
        if (!mounted) return;
        setState(() {
          _isAppLockEnabled = false;
          _isLocked = false;
        });
      },
    );
  }

  void _showTimerDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AutoDeleteTimerDialog(
        selectedMinutes: _autoDeleteMinutes,
        onSelected: _setAutoDeleteTimer,
      ),
    );
  }

  Future<void> _setAutoDeleteTimer(AutoDeleteTimerChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autoDeleteMinutes', choice.minutes);

    if (!mounted) return;
    setState(() => _autoDeleteMinutes = choice.minutes);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocalizationService.getFormatted('timer_set_msg', [choice.label]),
        ),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _deleteItem(ClipboardItem item) {
    setState(() {
      _optimisticDeletedIds.add(item.id);
    });
    _db.deleteItem(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocalizationService.get('deleted_toast'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lockApp();
    }

    if (state == AppLifecycleState.resumed) {
      _checkQuickSync();
    }
  }

  @override
  void onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      _lockApp();
      await windowManager.hide();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _desktopSyncSubscription?.cancel();
    _clipboardBackupTimer?.cancel();
    _uploadCoordinator.dispose();
    _searchController.dispose();
    _unlockPinController.dispose();

    if (PlatformService.isDesktop) {
      try {
        clipboardWatcher.removeListener(this);
        clipboardWatcher.stop();
      } catch (e) {
        debugPrint('Clipboard watcher stop failed: $e');
      }
      windowManager.removeListener(this);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: LocalizationService.currentLang,
      builder: (context, lang, child) {
        if (_isLocked) {
          return _buildLockedScaffold();
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            actions: [
              _buildTopIconButton(
                tooltip: AppThemeService.isDark ? 'Light mode' : 'Dark mode',
                onPressed: AppThemeService.toggle,
                icon: AppThemeService.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              _buildLanguageTopButton(lang),
              _buildTopIconButton(
                icon: _isNotificationEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                active: _isNotificationEnabled,
                tooltip: LocalizationService.get('status_notifications'),
                onPressed: _toggleNotification,
              ),
              _buildTopIconButton(
                icon: Icons.timer_rounded,
                active: _autoDeleteMinutes > 0,
                tooltip: LocalizationService.get('timer_title'),
                onPressed: _showTimerDialog,
              ),
              _buildTopIconButton(
                icon: Icons.logout_rounded,
                tooltip: LocalizationService.get('logout_title'),
                danger: true,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(LocalizationService.get('logout_title')),
                      content: Text(LocalizationService.get('logout_msg')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(LocalizationService.get('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _logout();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: Text(LocalizationService.get('btn_logout')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryColor,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'BridgeClip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${LocalizationService.get('room_short_label')} ${_compactRoomId(widget.roomId)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            LocalizationService.get('sync_ready'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.qr_code_rounded, color: _primaryColor),
                  title: Text(
                    LocalizationService.get('connect_new_device'),
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Future<void>.delayed(const Duration(milliseconds: 160), () {
                      if (mounted) _showConnectDeviceSheet();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.list,
                    color: !_isArchiveTab && !_isDeviceManagementTab
                        ? _primaryColor
                        : _mutedTextColor,
                  ),
                  title: Text(
                    LocalizationService.get('clipboard'),
                    style: TextStyle(
                      color: !_isArchiveTab && !_isDeviceManagementTab
                          ? _primaryColor
                          : _textColor,
                    ),
                  ),
                  selected: !_isArchiveTab && !_isDeviceManagementTab,
                  onTap: () {
                    setState(() {
                      _isArchiveTab = false;
                      _isDeviceManagementTab = false;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.archive,
                    color: _isArchiveTab && !_isDeviceManagementTab
                        ? _primaryColor
                        : _mutedTextColor,
                  ),
                  title: Text(
                    LocalizationService.get('archive'),
                    style: TextStyle(
                      color: _isArchiveTab && !_isDeviceManagementTab
                          ? _primaryColor
                          : _textColor,
                    ),
                  ),
                  selected: _isArchiveTab && !_isDeviceManagementTab,
                  onTap: () {
                    setState(() {
                      _isArchiveTab = true;
                      _isDeviceManagementTab = false;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.devices,
                    color: _isDeviceManagementTab
                        ? _primaryColor
                        : _mutedTextColor,
                  ),
                  title: Text(
                    LocalizationService.get('device_management'),
                    style: TextStyle(
                      color: _isDeviceManagementTab
                          ? _primaryColor
                          : _textColor,
                    ),
                  ),
                  selected: _isDeviceManagementTab,
                  onTap: () {
                    setState(() => _isDeviceManagementTab = true);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    _isAppLockEnabled ? Icons.lock : Icons.lock_open,
                    color: _isAppLockEnabled ? _primaryColor : _mutedTextColor,
                  ),
                  title: Text(
                    LocalizationService.get('app_lock_title'),
                    style: TextStyle(
                      color: _isAppLockEnabled ? _primaryColor : _textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAppLockDialog();
                  },
                ),
              ],
            ),
          ),
          body: _isDeviceManagementTab
              ? _buildDeviceManagementBody(lang)
              : _buildClipboardBody(lang),
        );
      },
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
    bool danger = false,
  }) {
    return TopIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      primaryColor: _primaryColor,
      mutedTextColor: _mutedTextColor,
      softFillColor: _softFillColor,
      borderColor: _borderColor,
      active: active,
      danger: danger,
    );
  }

  Widget _buildLanguageTopButton(AppLang lang) {
    final label = lang == AppLang.ko ? 'KO' : 'EN';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: LocalizationService.get('language_en'),
        child: InkWell(
          onTap: () => _showChoiceSheet<AppLang>(
            title: LocalizationService.get('language_title'),
            value: lang,
            options: const [AppLang.ko, AppLang.en],
            labelFor: (value) => value == AppLang.ko
                ? LocalizationService.get('language_ko')
                : LocalizationService.get('language_en'),
            iconFor: (_) => Icons.language_rounded,
            onSelected: LocalizationService.setLanguage,
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _softFillColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_rounded, color: _primaryColor, size: 19),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedScaffold() {
    return LockedScaffold(
      pinController: _unlockPinController,
      primaryColor: _primaryColor,
      textColor: _textColor,
      mutedTextColor: _mutedTextColor,
      onUnlock: _unlockApp,
    );
  }

  Widget _buildClipboardBody(AppLang lang) {
    return ClipboardBody(
      roomId: widget.roomId,
      clipboardStream: _db.clipboardStream,
      lang: lang,
      isArchiveTab: _isArchiveTab,
      notificationsEnabled: _isNotificationEnabled,
      searchController: _searchController,
      searchQuery: _searchQuery,
      deviceFilter: _deviceFilter,
      timeFilter: _timeFilter,
      primaryColor: _primaryColor,
      surfaceColor: _surfaceColor,
      softFillColor: _softFillColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedTextColor: _mutedTextColor,
      visibleItemsFor: _visibleItems,
      filteredItemsFor: _filteredItems,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      },
      onClearSearch: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      onShowDeviceFilter: (deviceOptions) => _showChoiceSheet<String>(
        title: _deviceFilter == 'all'
            ? LocalizationService.get('filter_all_devices')
            : _deviceFilter,
        value: _deviceFilter,
        options: deviceOptions,
        labelFor: (value) => value == 'all'
            ? LocalizationService.get('filter_all_devices')
            : value,
        iconFor: (_) => Icons.devices,
        onSelected: (selected) => setState(() => _deviceFilter = selected),
      ),
      onShowTimeFilter: () => _showChoiceSheet<String>(
        title: switch (_timeFilter) {
          'today' => LocalizationService.get('filter_today'),
          'week' => LocalizationService.get('filter_this_week'),
          _ => LocalizationService.get('filter_all_time'),
        },
        value: _timeFilter,
        options: const ['all', 'today', 'week'],
        labelFor: (value) => switch (value) {
          'today' => LocalizationService.get('filter_today'),
          'week' => LocalizationService.get('filter_this_week'),
          _ => LocalizationService.get('filter_all_time'),
        },
        iconFor: (_) => Icons.schedule,
        onSelected: (selected) => setState(() => _timeFilter = selected),
      ),
      onClearFilters: () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _deviceFilter = 'all';
          _timeFilter = 'all';
        });
      },
      onConnectDevice: _showConnectDeviceSheet,
      onCopy: (item) => _copyToLocalClipboard(item.content),
      onTogglePin: (item) => _db.togglePin(item.id, item.isPinned),
      onDelete: _deleteItem,
    );
  }

  String _compactRoomId(String roomId) {
    if (roomId.length <= 18) return roomId;
    return '${roomId.substring(0, 11)}...${roomId.substring(roomId.length - 4)}';
  }

  String _joinLink() {
    return 'bridgeclip://join?room=${Uri.encodeComponent(widget.roomId)}';
  }

  Future<void> _copyConnectionText(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.get('connection_copied')),
        backgroundColor: _primaryColor,
      ),
    );
  }

  void _showConnectDeviceSheet() {
    final link = _joinLink();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => ConnectDeviceSheet(
        roomId: widget.roomId,
        link: link,
        primaryColor: _primaryColor,
        surfaceColor: _surfaceColor,
        softFillColor: _softFillColor,
        borderColor: _borderColor,
        textColor: _textColor,
        mutedTextColor: _mutedTextColor,
        onCopyRoomId: () => _copyConnectionText(widget.roomId),
        onCopyLink: () => _copyConnectionText(link),
      ),
    );
  }

  Future<void> _showChoiceSheet<T>({
    required String title,
    required T value,
    required List<T> options,
    required String Function(T value) labelFor,
    required FutureOr<void> Function(T value) onSelected,
    IconData Function(T value)? iconFor,
  }) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (context) => ChoiceSheet<T>(
        title: title,
        value: value,
        options: options,
        labelFor: labelFor,
        iconFor: iconFor,
        primaryColor: _primaryColor,
        surfaceColor: _surfaceColor,
        softFillColor: _softFillColor,
        borderColor: _borderColor,
        textColor: _textColor,
        mutedTextColor: _mutedTextColor,
      ),
    );

    if (selected != null) {
      await onSelected(selected);
    }
  }

  Widget _buildDeviceManagementBody(AppLang lang) {
    return DeviceManagementBody(
      roomId: widget.roomId,
      deviceStream: _db.watchDevices(),
      lang: lang,
      currentDeviceId: _currentDeviceId,
      notificationsEnabled: _isNotificationEnabled,
      appLockEnabled: _isAppLockEnabled,
      launchAtStartupEnabled: _launchAtStartupEnabled,
      primaryColor: _primaryColor,
      surfaceColor: _surfaceColor,
      borderColor: _borderColor,
      textColor: _textColor,
      mutedTextColor: _mutedTextColor,
      onConnectDevice: _showConnectDeviceSheet,
      onRenameCurrentDevice: _showRenameDeviceDialog,
      onRemoveDevice: _removeDevice,
      onCurrentDeviceNotificationsChanged: (value) async {
        await _db.setCurrentDeviceNotifications(value);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isNotificationEnabled', value);
        if (!mounted) return;
        setState(() => _isNotificationEnabled = value);
      },
    );
  }

  void _removeDevice(DeviceInfo device) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.get('remove_device')),
        content: Text(
          device.isCurrentDevice
              ? LocalizationService.get('remove_current_device_msg')
              : LocalizationService.getFormatted('remove_device_msg', [
                  device.deviceName,
                ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (device.isCurrentDevice) {
                await _removeCurrentDeviceAndLogout();
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              await _db.deleteDevice(device.id);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(LocalizationService.get('device_removed')),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(LocalizationService.get('remove_device')),
          ),
        ],
      ),
    );
  }

  List<ClipboardItem> _visibleItems(List<ClipboardItem> allItems) {
    final now = DateTime.now();
    final items = <ClipboardItem>[];

    for (final item in allItems) {
      if (_optimisticDeletedIds.contains(item.id)) continue;

      if (_autoDeleteMinutes > 0 && !item.isPinned) {
        final expired =
            now.difference(item.timestamp).inMinutes >= _autoDeleteMinutes;
        if (expired) {
          Future.microtask(() => _db.deleteItem(item.id));
          continue;
        }
      }

      if (_isArchiveTab == item.isPinned) {
        items.add(item);
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<ClipboardItem> _filteredItems(List<ClipboardItem> visibleItems) {
    final now = DateTime.now();
    return visibleItems.where((item) {
      if (_searchQuery.isNotEmpty) {
        final target = '${item.content} ${item.deviceName} ${item.platform}'
            .toLowerCase();
        if (!target.contains(_searchQuery)) return false;
      }

      if (_deviceFilter != 'all' && item.deviceName != _deviceFilter) {
        return false;
      }

      if (_timeFilter == 'today') {
        final isSameDay =
            item.timestamp.year == now.year &&
            item.timestamp.month == now.month &&
            item.timestamp.day == now.day;
        if (!isSameDay) return false;
      } else if (_timeFilter == 'week') {
        if (now.difference(item.timestamp).inDays >= 7) return false;
      }

      return true;
    }).toList();
  }

}
