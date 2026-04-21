import 'package:flutter/services.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'dart:io' show Platform;
import 'database_service.dart';

class ClipboardService extends ClipboardListener {
  final DatabaseService _dbService;
  String? _lastCopiedText;

  ClipboardService(this._dbService) {
    // Start listening to the system clipboard on Desktop
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  // Gets called automatically when Windows or Mac clipboard changes
  @override
  void onClipboardChanged() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text != null && text.isNotEmpty && text != _lastCopiedText) {
      _lastCopiedText = text;
      
      // Determine what device is doing the copying
      String platformName = 'unknown';
      if (Platform.isWindows) platformName = 'windows';
      if (Platform.isMacOS) platformName = 'macos';
      if (Platform.isAndroid) platformName = 'android';
      if (Platform.isIOS) platformName = 'ios';
      
      String deviceName = Platform.localHostname;

      // Send instantly to Firebase
      await _dbService.addClipboardItem(text, deviceName, platformName);
      print("🚀 텍스트 복사 감지! Firebase 업로드 완료: $text");
    }
  }

  // Helper to manually copy text (When user taps a card in the app)
  static Future<void> copyToLocal(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
