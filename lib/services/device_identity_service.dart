import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  static const _deviceIdKey = 'deviceId';
  static const _deviceNameKey = 'deviceName';

  static String defaultDeviceName() {
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isAndroid) return 'Android Phone';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isLinux) return 'Linux Desktop';
    return 'Unknown Device';
  }

  static String platformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_deviceIdKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final id =
        '${platformName()}-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  static Future<String> deviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_deviceNameKey);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return defaultDeviceName();
  }

  static Future<void> setDeviceName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceNameKey, trimmed);
  }

  static Future<void> clearDeviceIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceNameKey);
  }
}
