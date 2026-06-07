import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const _enabledKey = 'appLockEnabled';
  static const _saltKey = 'appLockSalt';
  static const _hashKey = 'appLockHash';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> enable(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _createSalt();
    final hash = await _hashPin(pin, salt);
    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_saltKey, salt);
    await prefs.setString(_hashKey, hash);
  }

  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enabledKey);
    await prefs.remove(_saltKey);
    await prefs.remove(_hashKey);
  }

  static Future<bool> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_saltKey);
    final expectedHash = prefs.getString(_hashKey);
    if (salt == null || expectedHash == null) return false;

    final actualHash = await _hashPin(pin, salt);
    return actualHash == expectedHash;
  }

  static String _createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static Future<String> _hashPin(String pin, String salt) async {
    final digest = await Sha256().hash(utf8.encode('$salt:$pin'));
    return base64Encode(digest.bytes);
  }
}
