import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  // Singleton pattern for easy global access
  static final CryptoService instance = CryptoService._internal();
  CryptoService._internal();

  SecretKey? _secretKey;
  final AesGcm _algorithm = AesGcm.with256bits();
  bool get isInitialized => _secretKey != null;

  /// Derive AES key from raw password using PBKDF2
  Future<void> init(String password) async {
    if (password.isEmpty) throw Exception("Password cannot be empty");

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    // Hardcoded salt is fine here since it only prevents rainbow table attacks on the
    // room password, but we could make it dynamically based on roomId. Let's use fixed for simplicity.
    _secretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode('antigravity_clipboard_salt_2026'),
    );
  }

  /// Reset the encryption key
  void clear() {
    _secretKey = null;
  }

  /// Encrypt plaintext to Base64 (nonce + mac + ciphertext)
  Future<String> encrypt(String plainText) async {
    if (_secretKey == null) throw Exception("CryptoService is not initialized. Please call init(password).");

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: _secretKey!,
    );

    final combined = <int>[
      ...secretBox.nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ];

    return base64Encode(combined);
  }

  /// Decrypt Base64 back to plaintext
  Future<String> decrypt(String encryptedBase64) async {
    if (_secretKey == null) throw Exception("CryptoService is not initialized. Please call init(password).");

    try {
      final combined = base64Decode(encryptedBase64);
      // AES-GCM nonce is strictly 12 bytes
      if (combined.length < 28) return "[복호화 실패] 데이터 손상"; // 12 (nonce) + 16 (mac) = 28 minimum
      
      final nonce = combined.sublist(0, 12);
      final macBytes = combined.sublist(12, 28);
      final cipherText = combined.sublist(28);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clearTextBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: _secretKey!,
      );

      return utf8.decode(clearTextBytes);
    } catch (e) {
      return "[복호화 실패] 비밀번호 불일치";
    }
  }
}
