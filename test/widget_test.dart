import 'package:clipboard_sync/main.dart';
import 'package:clipboard_sync/services/database_service.dart';
import 'package:clipboard_sync/services/localization.dart';
import 'package:clipboard_sync/state/global_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('BridgeClip login screen renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    LocalizationService.currentLang.value = AppLang.en;

    await tester.pumpWidget(const ClipboardSyncApp());

    expect(find.text('BridgeClip'), findsOneWidget);
    expect(find.text('Create Room'), findsOneWidget);
    expect(find.text('Join Room'), findsOneWidget);
    expect(find.text('Create Room and start'), findsOneWidget);
    expect(find.text('How to use BridgeClip'), findsOneWidget);
  });

  testWidgets('BridgeClip onboarding renders before first login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    LocalizationService.currentLang.value = AppLang.en;

    await tester.pumpWidget(
      const ClipboardSyncApp(initialShowOnboarding: true),
    );

    expect(find.text('Connect with the same Room'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('join link pre-fills login room id', (tester) async {
    SharedPreferences.setMockInitialValues({});
    LocalizationService.currentLang.value = AppLang.en;
    GlobalState.pendingJoinRoomId = 'BC-LINK-TEST-ROOM';

    await tester.pumpWidget(const ClipboardSyncApp());
    await tester.pump();

    expect(find.text('Join Room'), findsWidgets);
    expect(find.text('BC-LINK-TEST-ROOM'), findsOneWidget);
    GlobalState.pendingJoinRoomId = null;
  });

  test('settings localization keys resolve', () {
    LocalizationService.currentLang.value = AppLang.en;

    expect(LocalizationService.get('settings'), 'Settings');
    expect(LocalizationService.get('settings_theme'), 'Theme');
    expect(LocalizationService.get('settings_connection'), 'Connection');
    expect(LocalizationService.get('status_auto_start'), 'Auto-start');

    LocalizationService.currentLang.value = AppLang.ko;
    expect(LocalizationService.get('settings'), '설정');
    expect(LocalizationService.get('language_ko'), '한국어');
    expect(LocalizationService.get('status_on'), '켜짐');
  });

  test('generated room id uses the BridgeClip invite format', () {
    final roomId = DatabaseService.generateRoomId();

    expect(DatabaseService.isGeneratedRoomId(roomId), isTrue);
    expect(roomId.startsWith('BC-'), isTrue);
  });
}
