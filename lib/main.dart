import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/crypto_service.dart';
import 'services/database_service.dart';
import 'models/clipboard_item.dart';
import 'screens/login_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:app_links/app_links.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'dart:async';
import 'dart:io' show Platform, exit;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class GlobalState {
  static String? pendingSelectCopyText;
  static final ValueNotifier<String?> selectCopyNotifier = ValueNotifier<String?>(null);
  
  static String? pendingCopyText;
  static final ValueNotifier<String?> copyNotifier = ValueNotifier<String?>(null);
}

class DesktopTrayListener with TrayListener {
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await windowManager.show();
      await windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }
}
final desktopTrayListener = DesktopTrayListener();



@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (notificationResponse.actionId == 'copy' || notificationResponse.actionId == 'select_copy') {
    final text = notificationResponse.payload;
    if (text != null && text.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final roomPassword = prefs.getString('roomPassword');
        if (roomPassword != null) {
          await CryptoService.instance.init(roomPassword);
          final clearText = await CryptoService.instance.decrypt(text);
          final encoded = Uri.encodeComponent(clearText);
          final host = notificationResponse.actionId == 'select_copy' ? 'select_copy' : 'copy';
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'copysync://$host?text=$encoded',
            flags: <int>[268435456], // FLAG_ACTIVITY_NEW_TASK
          );
          await intent.launch();
        }
      } catch (e) {
        print("복사 실패: $e");
      }
    }
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('isNotificationEnabled') ?? true;
  if (!isEnabled) return;

  final title = message.data['title'] ?? '클립보드 동기화';
  final body = message.data['body'] ?? '데이터가 수신되었습니다.';
  final text = message.data['text'] ?? '';

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'clipboard_channel',
    '클립보드 알림',
    importance: Importance.max,
    priority: Priority.high,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction('copy', '복사하기', showsUserInterface: true),
      AndroidNotificationAction('select_copy', '선택 복사', showsUserInterface: true),
    ],
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  
  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecond,
    title: title,
    body: body,
    notificationDetails: platformChannelSpecifics,
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
  if (response.actionId == 'copy' || response.actionId == 'select_copy') {
    final text = response.payload;
    if (text != null && text.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final roomPassword = prefs.getString('roomPassword');
        if (roomPassword != null) {
          await CryptoService.instance.init(roomPassword);
          final clearText = await CryptoService.instance.decrypt(text);
          if (response.actionId == 'copy') {
             GlobalState.pendingCopyText = clearText;
             GlobalState.copyNotifier.value = DateTime.now().millisecondsSinceEpoch.toString();
          } else {
             GlobalState.pendingSelectCopyText = clearText;
             GlobalState.selectCopyNotifier.value = DateTime.now().millisecondsSinceEpoch.toString();
          }
        }
      } catch (e) {
        print("전면 복사 실패: $e");
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (Platform.isAndroid || Platform.isIOS) {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotification,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final launchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
         _handleLocalNotification(response);
      }
    }
  }
  
  final prefs = await SharedPreferences.getInstance();
  final roomId = prefs.getString('roomId');
  final roomPassword = prefs.getString('roomPassword');

    if (roomId != null && roomPassword != null) {
      try {
        await CryptoService.instance.init(roomPassword);
      } catch (e) {
        // Ignored
      }
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(800, 600),
        center: true,
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.normal,
        title: 'BridgeClip',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.hide();
      });

      launchAtStartup.setup(
        appName: 'BridgeClip',
        appPath: Platform.resolvedExecutable,
      );
      await launchAtStartup.enable();

      await trayManager.setIcon(Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png');
      List<MenuItem> items = [
        MenuItem(key: 'show_window', label: '설정 화면 열기'),
        MenuItem(key: 'auto_start', label: '시작프로그램 등록완료 (BridgeClip)'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: '완전 종료'),
      ];
      await trayManager.setContextMenu(Menu(items: items));
      trayManager.addListener(desktopTrayListener);
    }

  runApp(ClipboardSyncApp(initialRoomId: roomId, initialRoomPassword: roomPassword));
}

class ClipboardSyncApp extends StatelessWidget {
  final String? initialRoomId;
  final String? initialRoomPassword;
  const ClipboardSyncApp({super.key, this.initialRoomId, this.initialRoomPassword});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgeClip',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: const Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: (initialRoomId == null || initialRoomPassword == null) ? const LoginScreen() : ClipboardHome(roomId: initialRoomId!),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ClipboardHome extends StatefulWidget {
  final String roomId;
  const ClipboardHome({super.key, required this.roomId});

  @override
  State<ClipboardHome> createState() => _ClipboardHomeState();
}

class _ClipboardHomeState extends State<ClipboardHome> with WidgetsBindingObserver, WindowListener {
  late final DatabaseService _db;
  final List<String> _optimisticDeletedIds = [];
  String _lastCopiedByApp = "";
  Timer? _clipboardTimer;
  int _autoDeleteMinutes = 0;
  bool _isArchiveTab = false;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isNotificationEnabled = true;
  static const MethodChannel quickSyncChannel = MethodChannel('com.antigravity/quick_sync');

  String _getDeviceName() {
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isAndroid) return 'Android Phone';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isMacOS) return 'MacBook';
    return 'Unknown Device';
  }

  String _getPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(roomId: widget.roomId);
    
    _initClipboardState();
    _initAppLinks();

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _checkClipboardPeriodic();
      });

      _db.clipboardStream.listen((items) {
        if (items.isNotEmpty) {
          final latest = items.first;
          if (latest.deviceName != _getDeviceName() && _lastCopiedByApp != latest.content) {
             _copyToLocalClipboard(latest.content);
          }
        }
      });
    }
    
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
    }
    _loadExpireSettings();
    _loadNotificationSettings();
    _checkQuickSync();
    _setupFcm();

    // Deterministic select_copy handler (Bypass OS intent reflection)
    GlobalState.selectCopyNotifier.addListener(() {
      if (GlobalState.pendingSelectCopyText != null && mounted) {
        _showSelectCopyDialog(GlobalState.pendingSelectCopyText!);
        GlobalState.pendingSelectCopyText = null;
      }
    });

    if (GlobalState.pendingSelectCopyText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSelectCopyDialog(GlobalState.pendingSelectCopyText!);
          GlobalState.pendingSelectCopyText = null;
        }
      });
    }

    // Deterministic copy handler to guarantee Window Focus before clipboard write
    void _executeSafeCopy(String text) async {
      bool success = false;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200)); // Ensure window focus acquired
        try {
          await Clipboard.setData(ClipboardData(text: text));
          success = true;
          break; // Succeeded!
        } catch (e) {
          // Keep trying until focus is fully acquired
        }
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 클립보드에 바로 복사되었습니다!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.blueAccent, duration: Duration(milliseconds: 800)),
        );
        await Future.delayed(const Duration(milliseconds: 800)); // Show feedback briefly
      }
      
      SystemNavigator.pop();
    }

    GlobalState.copyNotifier.addListener(() {
      if (GlobalState.pendingCopyText != null && mounted) {
        final text = GlobalState.pendingCopyText!;
        GlobalState.pendingCopyText = null;
        _executeSafeCopy(text);
      }
    });

    if (GlobalState.pendingCopyText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final text = GlobalState.pendingCopyText!;
          GlobalState.pendingCopyText = null;
          _executeSafeCopy(text);
        }
      });
    }
  }

  void _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
    });
  }

  void _toggleNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_isNotificationEnabled;
    await prefs.setBool('isNotificationEnabled', newValue);
    setState(() {
      _isNotificationEnabled = newValue;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newValue ? '알림이 켜졌습니다.' : '알림이 꺼졌습니다.', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent),
      );
    }
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'copysync' || uri.scheme == 'appclip') {
        final text = uri.queryParameters['text'];
        if (text != null) {
          if (uri.host == 'copy') {
            _copyToLocalClipboard(text);
          } else if (uri.host == 'select_copy') {
            _showSelectCopyDialog(text);
          }
        }
      }
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null && (uri.scheme == 'copysync' || uri.scheme == 'appclip')) {
        final text = uri.queryParameters['text'];
        if (text != null) {
          if (uri.host == 'copy') {
            _copyToLocalClipboard(text);
          } else if (uri.host == 'select_copy') {
            _showSelectCopyDialog(text);
          }
        }
      }
    });
  }

  void _showSelectCopyDialog(String text) {
    if (!mounted) return;
    final TextEditingController controller = TextEditingController(text: text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('부분 선택 복사 편집기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: null, // Allow multiline
            keyboardType: TextInputType.multiline,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withOpacity(0.2),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                _copyToLocalClipboard(controller.text);
                Navigator.pop(context);
              },
              child: const Text('수정 복사', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _initClipboardState() async {
    try {
      ClipboardData? initial = await Clipboard.getData(Clipboard.kTextPlain);
      if (initial != null && initial.text != null) {
        _lastCopiedByApp = initial.text!;
      }
    } catch (e) {
      print("Init Clipboard fetch error: $e");
    }
  }

  void _checkClipboardPeriodic() async {
    try {
      ClipboardData? newClipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (newClipboardData != null && newClipboardData.text != null && newClipboardData.text!.isNotEmpty) {
        final text = newClipboardData.text!;
        if (_lastCopiedByApp == text) return;
        
        print("클립보드 변화 감지!: $text");
        _db.addClipboardItem(text, _getDeviceName(), Platform.operatingSystem);
        _lastCopiedByApp = text; 
      }
    } catch (e) {
      print("클립보드 읽기 에러: $e");
    }
  }

  Future<void> _loadExpireSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoDeleteMinutes = prefs.getInt('autoDeleteMinutes') ?? 0;
    });
  }

  Future<void> _setupFcm() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      
      String? token = await messaging.getToken();
      if (token != null) {
        await _db.saveFcmToken(_getDeviceName(), token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db.saveFcmToken(_getDeviceName(), newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (message.data.isNotEmpty) {
          await _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        final text = message.data['text'];
        if (text != null && text.toString().isNotEmpty) {
           final clearText = await CryptoService.instance.decrypt(text.toString());
           _copyToLocalClipboard(clearText);
        }
      });
      
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final text = initialMessage.data['text'];
        if (text != null && text.toString().isNotEmpty) {
           final clearText = await CryptoService.instance.decrypt(text.toString());
           _copyToLocalClipboard(clearText);
        }
      }
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkQuickSync();
    }
  }

  Future<void> _checkQuickSync() async {
    if (!Platform.isAndroid) return;
    try {
      final bool isQuickSync = await quickSyncChannel.invokeMethod('checkQuickSync');
      if (isQuickSync) {
        ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.trim().isNotEmpty) {
          // Send to DB explicitly without triggering duplicate checks, though _lastCopiedByApp ignores only inward syncs.
          await _db.addClipboardItem(text, _getDeviceName(), _getPlatform());
        }
        SystemNavigator.pop();
      }
    } catch (e) {
      // Ignored
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _clipboardTimer?.cancel();
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      windowManager.hide();
    }
  }

  void _copyToLocalClipboard(String text) async {
    _lastCopiedByApp = text;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('클립보드에 복사되었습니다!', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1000),
      ),
    );
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roomId');
    await prefs.remove('roomPassword');
    CryptoService.instance.clear();
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('자동 삭제 타이머 ⏱️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimerOption('기기 영구 보관', 0),
              _buildTimerOption('1분 뒤 자동 삭제', 1),
              _buildTimerOption('10분 뒤 자동 삭제', 10),
              _buildTimerOption('1시간 뒤 자동 삭제', 60),
              _buildTimerOption('1일 뒤 자동 삭제', 1440),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildTimerOption(String title, int minutes) {
    bool isSelected = _autoDeleteMinutes == minutes;
    return ListTile(
      title: Text(title, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('autoDeleteMinutes', minutes);
        setState(() => _autoDeleteMinutes = minutes);
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('타이머가 $title(으)로 설정되었습니다.'), backgroundColor: Colors.blueAccent),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isArchiveTab ? '영구 보관함' : '일반 클립보드', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isNotificationEnabled ? Icons.notifications_active : Icons.notifications_off, color: _isNotificationEnabled ? Colors.blueAccent : Colors.white54),
            onPressed: _toggleNotification,
          ),
          IconButton(
            icon: Icon(Icons.timer, color: _autoDeleteMinutes > 0 ? Colors.blueAccent : Colors.white70),
            onPressed: _showTimerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('로그아웃', style: TextStyle(color: Colors.white)),
                  content: const Text('현재 서랍에서 로그아웃하시겠습니까?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white54))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.dashboard, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text('서랍장 메뉴', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.list, color: !_isArchiveTab ? Colors.blueAccent : Colors.white70),
              title: Text('일반 클립보드', style: TextStyle(color: !_isArchiveTab ? Colors.blueAccent : Colors.white)),
              selected: !_isArchiveTab,
              onTap: () {
                setState(() => _isArchiveTab = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.archive, color: _isArchiveTab ? Colors.blueAccent : Colors.white70),
              title: Text('영구 보관함', style: TextStyle(color: _isArchiveTab ? Colors.blueAccent : Colors.white)),
              selected: _isArchiveTab,
              onTap: () {
                setState(() => _isArchiveTab = true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<ClipboardItem>>(
        stream: _db.clipboardStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final allItems = snapshot.data ?? [];
          final now = DateTime.now();
          final List<ClipboardItem> items = [];

          for (var item in allItems) {
            if (_optimisticDeletedIds.contains(item.id)) continue;
            
            if (_autoDeleteMinutes > 0 && !item.isPinned) {
              if (now.difference(item.timestamp).inMinutes >= _autoDeleteMinutes) {
                Future.microtask(() => _db.deleteItem(item.id));
                continue;
              }
            }
            
            if (_isArchiveTab) {
              if (item.isPinned) items.add(item);
            } else {
              if (!item.isPinned) items.add(item);
            }
          }

          items.sort((a, b) {
            if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
            return b.timestamp.compareTo(a.timestamp);
          });
          
          if (items.isEmpty) {
            return const Center(
              child: Text('클립보드가 비어 있습니다.\nPC나 스마트폰에서 내용을 복사해보세요!', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              IconData deviceIcon;
              if (item.platform == 'macos') deviceIcon = Icons.laptop_mac;
              else if (item.platform == 'windows') deviceIcon = Icons.computer;
              else if (item.platform == 'ios') deviceIcon = Icons.phone_iphone;
              else if (item.platform == 'android') deviceIcon = Icons.phone_android;
              else deviceIcon = Icons.devices;

              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  setState(() {
                    _optimisticDeletedIds.add(item.id);
                  });
                  _db.deleteItem(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('삭제되었습니다!', style: TextStyle(color: Colors.white)), 
                      backgroundColor: Colors.redAccent, 
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(deviceIcon, color: Colors.blueAccent),
                    ),
                    title: Text(
                      item.content,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(item.deviceName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          const SizedBox(width: 8),
                          Text('Unknown', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          const SizedBox(width: 8),
                          Text(timeago.format(item.timestamp, locale: 'ko'), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: () {
                            _lastCopiedByApp = item.content;
                            _copyToLocalClipboard(item.content);
                          },
                        ),
                        IconButton(
                          icon: Icon(item.isPinned ? Icons.unarchive : Icons.archive, color: item.isPinned ? Colors.blueAccent : Colors.white54),
                          onPressed: () => _db.togglePin(item.id, item.isPinned),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _optimisticDeletedIds.add(item.id);
                            });
                            _db.deleteItem(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('삭제되었습니다!', style: TextStyle(color: Colors.white)), 
                                backgroundColor: Colors.redAccent, 
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(milliseconds: 1000),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () => _copyToLocalClipboard(item.content),
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}

