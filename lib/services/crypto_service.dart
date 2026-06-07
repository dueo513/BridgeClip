import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final CryptoService instance = CryptoService._internal();
  CryptoService._internal();

  static const _salt = 'antigravity_clipboard_salt_2026';

  SecretKey? _secretKey;
  final AesGcm _algorithm = AesGcm.with256bits();

  bool get isInitialized => _secretKey != null;

  Future<void> init(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty.');
    }

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    _secretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode(_salt),
    );
  }

  void clear() {
    _secretKey = null;
  }

  Future<String> encrypt(String plainText) async {
    final secretKey = _secretKey;
    if (secretKey == null) {
      throw StateError('CryptoService must be initialized before encrypting.');
    }

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
    );

    return base64Encode([
      ...secretBox.nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ]);
  }

  Future<String> contentHash(String plainText) async {
    final secretKey = _secretKey;
    if (secretKey == null) {
      throw StateError(
        'CryptoService must be initialized before hashing content.',
      );
    }

    final normalized = plainText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(normalized),
      secretKey: secretKey,
    );
    return base64UrlEncode(mac.bytes).replaceAll('=', '');
  }

  Future<String> decrypt(String encryptedBase64) async {
    final secretKey = _secretKey;
    if (secretKey == null) {
      throw StateError('CryptoService must be initialized before decrypting.');
    }

    try {
      final combined = base64Decode(encryptedBase64);
      if (combined.length < 28) {
        return '[Decryption failed] Invalid encrypted data.';
      }

      final secretBox = SecretBox(
        combined.sublist(28),
        nonce: combined.sublist(0, 12),
        mac: Mac(combined.sublist(12, 28)),
      );

      final clearTextBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(clearTextBytes);
    } catch (_) {
      return '[Decryption failed] Password mismatch or damaged data.';
    }
  }
}
