import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { ko, en }

class LocalizationService {
  static final ValueNotifier<AppLang> currentLang = ValueNotifier<AppLang>(AppLang.ko);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_lang');
    if (savedLang == 'en') {
      currentLang.value = AppLang.en;
    } else {
      currentLang.value = AppLang.ko;
    }
  }

  static Future<void> setLanguage(AppLang lang) async {
    currentLang.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang == AppLang.ko ? 'ko' : 'en');
  }

  static String get(String key) {
    if (currentLang.value == AppLang.ko) {
      return _ko[key] ?? key;
    } else {
      return _en[key] ?? key;
    }
  }

  static final Map<String, String> _ko = {
    // General
    'lang_label': 'Language / 언어',
    'ok': '확인',
    'cancel': '취소',
    'close': '닫기',
    
    // Login Screen
    'login_title': '나만의 클립보드 서랍장에 연결하세요.',
    'login_err_empty': '접속할 룸 코드와 비밀번호를 모두 입력해주세요.',
    'login_err_key': '암호화 키 생성에 실패했습니다.',
    'room_id_label': '룸 코드 (Room ID)',
    'room_id_hint': '예: my_secret_room',
    'password_label': '보안 암호 (Security Password)',
    'password_hint': '종단간 암호화(E2EE)에 사용됩니다',
    'btn_start_sync': '동기화 시작하기',
    'login_info': '다른 기기에서도 같은 코드를 입력하면 연동됩니다.',

    // Home Screen (Main)
    'menu': '메뉴',
    'clipboard': '클립보드',
    'archive': '보관함',
    'copied_toast': '클립보드에 복사되었습니다!',
    'empty_list': '클립보드가 비어 있습니다.\nPC나 폰에서 내용을 복사해보세요!',
    'empty_list_archive': '보관함이 비어 있습니다.',

    // Settings / Dialogs
    'timer_title': '자동 삭제 타이머 ⏱️',
    'timer_keep_forever': '삭제 안함',
    'timer_1m': '1분 뒤 자동 삭제',
    'timer_10m': '10분 뒤 자동 삭제',
    'timer_1h': '1시간 뒤 자동 삭제',
    'timer_1d': '1일 뒤 자동 삭제',
    'timer_set_msg': '타이머가 {0}(으)로 설정되었습니다.',
    'logout_title': '연동 해제',
    'logout_msg': '현재 서랍에서 로그아웃하시겠습니까?',
    'btn_logout': '로그아웃',

    // Tray Menu (Windows)
    'tray_show': '설정 화면 열기',
    'tray_ready': '시작프로그램 등록완료 (BridgeClip)',
    'tray_exit': '완전 종료',
  };

  static final Map<String, String> _en = {
    // General
    'lang_label': 'Language / 언어',
    'ok': 'OK',
    'cancel': 'Cancel',
    'close': 'Close',

    // Login Screen
    'login_title': 'Connect to your private clipboard vault.',
    'login_err_empty': 'Please enter both Room ID and Password.',
    'login_err_key': 'Failed to generate encryption key.',
    'room_id_label': 'Room ID',
    'room_id_hint': 'e.g. my_secret_room',
    'password_label': 'Security Password',
    'password_hint': 'Used for End-to-End Encryption (E2EE)',
    'btn_start_sync': 'Start Syncing',
    'login_info': 'Enter the same credentials on other devices to sync.',

    // Home Screen (Main)
    'menu': 'Menu',
    'clipboard': 'Clipboard',
    'archive': 'Archive',
    'copied_toast': 'Copied to clipboard!',
    'empty_list': 'Clipboard is empty.\nCopy something on your PC or Phone!',
    'empty_list_archive': 'Archive is empty.',

    // Settings / Dialogs
    'timer_title': 'Auto-Delete Timer ⏱️',
    'timer_keep_forever': 'Keep Forever',
    'timer_1m': 'Delete in 1 minute',
    'timer_10m': 'Delete in 10 minutes',
    'timer_1h': 'Delete in 1 hour',
    'timer_1d': 'Delete in 1 day',
    'timer_set_msg': 'Timer is set to {0}.',
    'logout_title': 'Disconnect',
    'logout_msg': 'Are you sure you want to log out from this vault?',
    'btn_logout': 'Log Out',

    // Tray Menu (Windows)
    'tray_show': 'Open Settings',
    'tray_ready': 'Added to Auto-Start (BridgeClip)',
    'tray_exit': 'Exit App',
  };

  // Helper for formatted strings
  static String getFormatted(String key, List<String> args) {
    String text = get(key);
    for (int i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', args[i]);
    }
    return text;
  }
}
