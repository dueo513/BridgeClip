import 'dart:io' show Platform;

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'database_service.dart';

class ClipboardService extends ClipboardListener {
  ClipboardService(this._dbService) {
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  final DatabaseService _dbService;
  String? _lastCopiedText;

  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  void onClipboardChanged() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.isEmpty || text == _lastCopiedText) return;

    _lastCopiedText = text;
    await _dbService.addClipboardItem(
      text,
      Platform.localHostname,
      _platformName(),
    );
    debugPrint('Clipboard uploaded from desktop listener.');
  }

  static Future<void> copyToLocal(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  String _platformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
