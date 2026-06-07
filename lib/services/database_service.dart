import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/clipboard_item.dart';
import '../models/device_info.dart';
import 'crypto_service.dart';
import 'device_identity_service.dart';

class DatabaseService {
  DatabaseService({required this.roomId});

  static const _roomAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _duplicateContentWindow = Duration(seconds: 15);
  static final Random _secureRandom = Random.secure();

  final String roomId;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  static _RestAuthSession? _restSession;

  CollectionReference<Map<String, dynamic>> get _clipboards =>
      _firestore.collection('users').doc(roomId).collection('clipboards');

  CollectionReference<Map<String, dynamic>> get _tokens =>
      _firestore.collection('users').doc(roomId).collection('tokens');

  DocumentReference<Map<String, dynamic>> get _room =>
      _firestore.collection('rooms').doc(roomId);

  static String generateRoomId() {
    String segment(int length) {
      return List.generate(
        length,
        (_) => _roomAlphabet[_secureRandom.nextInt(_roomAlphabet.length)],
      ).join();
    }

    return 'BC-${segment(4)}-${segment(4)}-${segment(4)}';
  }

  static bool isGeneratedRoomId(String value) {
    return RegExp(
      r'^BC-[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$',
    ).hasMatch(value.trim().toUpperCase());
  }

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  Future<String> _restIdToken() async {
    final now = DateTime.now().toUtc();
    final activeSession = _restSession;
    if (activeSession != null && activeSession.expiresAt.isAfter(now)) {
      return activeSession.idToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('firebaseRestIdToken');
    final storedExpiry = prefs.getInt('firebaseRestExpiresAt');
    if (storedToken != null && storedExpiry != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        storedExpiry,
        isUtc: true,
      );
      if (expiresAt.isAfter(now)) {
        _restSession = _RestAuthSession(storedToken, expiresAt);
        return storedToken;
      }
    }

    final apiKey = DefaultFirebaseOptions.windows.apiKey;
    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'returnSecureToken': true}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Anonymous sign-in failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final idToken = body['idToken'] as String?;
    final expiresIn = int.tryParse('${body['expiresIn'] ?? 3600}') ?? 3600;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Anonymous sign-in did not return an idToken.');
    }

    final expiresAt = now.add(Duration(seconds: expiresIn - 60));
    _restSession = _RestAuthSession(idToken, expiresAt);
    await prefs.setString('firebaseRestIdToken', idToken);
    await prefs.setInt(
      'firebaseRestExpiresAt',
      expiresAt.millisecondsSinceEpoch,
    );
    return idToken;
  }

  Uri _restUri(String path, [Map<String, String>? query]) {
    const projectId = 'shrud-clip-2026-78fee';
    return Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/$path',
      query,
    );
  }

  Future<Map<String, String>> _restHeaders() async {
    final idToken = await _restIdToken();
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _restFields(Map<String, dynamic> values) {
    return {
      for (final entry in values.entries)
        entry.key: switch (entry.value) {
          String value => {'stringValue': value},
          bool value => {'booleanValue': value},
          DateTime value => {'timestampValue': value.toUtc().toIso8601String()},
          int value => {'integerValue': value.toString()},
          double value => {'doubleValue': value},
          _ => {'nullValue': null},
        },
    };
  }

  Map<String, dynamic> _fromRestFields(Map<String, dynamic>? fields) {
    final result = <String, dynamic>{};
    if (fields == null) return result;

    for (final entry in fields.entries) {
      final value = entry.value as Map<String, dynamic>;
      if (value.containsKey('stringValue')) {
        result[entry.key] = value['stringValue'] as String;
      } else if (value.containsKey('booleanValue')) {
        result[entry.key] = value['booleanValue'] as bool;
      } else if (value.containsKey('timestampValue')) {
        result[entry.key] = DateTime.parse(value['timestampValue'] as String);
      } else if (value.containsKey('integerValue')) {
        result[entry.key] = int.tryParse(value['integerValue'] as String) ?? 0;
      } else if (value.containsKey('doubleValue')) {
        result[entry.key] = (value['doubleValue'] as num).toDouble();
      }
    }

    return result;
  }

  DateTime? _readDocumentTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is Timestamp) return value.toDate().toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  bool _isRecentDuplicateTimestamp(DateTime? timestamp) {
    if (timestamp == null) return false;
    return DateTime.now().toUtc().difference(timestamp).abs() <
        _duplicateContentWindow;
  }

  String _clipboardDocumentId(String contentHash, DateTime timestamp) {
    final bucket =
        timestamp.millisecondsSinceEpoch ~/
        _duplicateContentWindow.inMilliseconds;
    return 'clip_${contentHash}_$bucket';
  }

  Future<bool> _hasRecentDuplicateContentHash(String contentHash) async {
    if (contentHash.isEmpty) return false;

    if (Platform.isWindows) {
      final response = await http.get(
        _restUri('users/$roomId/clipboards', const {
          'pageSize': '25',
          'orderBy': 'timestamp desc',
        }),
        headers: await _restHeaders(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Clipboard duplicate lookup failed: ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final documents = (body['documents'] as List<dynamic>?) ?? const [];
      for (final document in documents.cast<Map<String, dynamic>>()) {
        final data = _fromRestFields(
          document['fields'] as Map<String, dynamic>?,
        );
        if (data['contentHash'] == contentHash &&
            _isRecentDuplicateTimestamp(_readDocumentTime(data['timestamp']))) {
          return true;
        }
      }
      return false;
    }

    await _ensureSignedIn();
    final snapshot = await _clipboards
        .orderBy('timestamp', descending: true)
        .limit(25)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['contentHash'] == contentHash &&
          _isRecentDuplicateTimestamp(_readDocumentTime(data['timestamp']))) {
        return true;
      }
    }
    return false;
  }

  Future<bool> roomExists() async {
    if (Platform.isWindows) {
      final response = await http.get(
        _restUri('rooms/${Uri.encodeComponent(roomId)}'),
        headers: await _restHeaders(),
      );

      if (response.statusCode == 404) return false;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Room lookup failed: ${response.body}');
      }
      return true;
    }

    await _ensureSignedIn();
    final snapshot = await _room.get();
    return snapshot.exists;
  }

  Future<void> createRoomRegistry() async {
    final deviceId = await DeviceIdentityService.deviceId();
    final now = DateTime.now().toUtc();
    final values = {
      'createdAt': now,
      'lastActiveAt': now,
      'createdByDeviceId': deviceId,
      'version': 1,
    };

    if (Platform.isWindows) {
      if (await roomExists()) {
        throw StateError('Room already exists.');
      }
      final response = await http.patch(
        _restUri('rooms/${Uri.encodeComponent(roomId)}'),
        headers: await _restHeaders(),
        body: jsonEncode({'fields': _restFields(values)}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Room create failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    if ((await _room.get()).exists) {
      throw StateError('Room already exists.');
    }
    await _room.set({
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'createdByDeviceId': deviceId,
      'version': 1,
    });
  }

  Future<void> ensureRoomRegistry() async {
    if (await roomExists()) {
      await touchRoomRegistry();
      return;
    }
    await createRoomRegistry();
  }

  Future<void> touchRoomRegistry() async {
    if (Platform.isWindows) {
      final response = await http.patch(
        _restUri('rooms/${Uri.encodeComponent(roomId)}', const {
          'updateMask.fieldPaths': 'lastActiveAt',
        }),
        headers: await _restHeaders(),
        body: jsonEncode({
          'fields': _restFields({'lastActiveAt': DateTime.now().toUtc()}),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Room touch failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _room.set({
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<ClipboardItem>> _fetchRestClipboardItems() async {
    final response = await http.get(
      _restUri('users/$roomId/clipboards', const {
        'pageSize': '100',
        'orderBy': 'timestamp desc',
      }),
      headers: await _restHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Clipboard fetch failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = (body['documents'] as List<dynamic>?) ?? const [];
    final items = <ClipboardItem>[];

    for (final document in documents.cast<Map<String, dynamic>>()) {
      final name = document['name'] as String;
      final id = name.substring(name.lastIndexOf('/') + 1);
      final data = _fromRestFields(document['fields'] as Map<String, dynamic>?);
      final rawContent = data['content'] as String? ?? '';
      final decryptedContent = await CryptoService.instance.decrypt(rawContent);

      items.add(
        ClipboardItem.fromMap(id, {...data, 'content': decryptedContent}),
      );
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<List<DeviceInfo>> _fetchRestDevices(String currentDeviceId) async {
    final response = await http.get(
      _restUri('users/$roomId/tokens', const {'pageSize': '100'}),
      headers: await _restHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Device fetch failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = (body['documents'] as List<dynamic>?) ?? const [];
    final devices = <DeviceInfo>[];

    for (final document in documents.cast<Map<String, dynamic>>()) {
      final name = document['name'] as String;
      final id = Uri.decodeComponent(name.substring(name.lastIndexOf('/') + 1));
      final data = _fromRestFields(document['fields'] as Map<String, dynamic>?);
      devices.add(
        DeviceInfo.fromMap(id, data, currentDeviceId: currentDeviceId),
      );
    }

    devices.sort((a, b) {
      if (a.isCurrentDevice) return -1;
      if (b.isCurrentDevice) return 1;
      final aTime =
          a.lastSeenAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastSeenAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return devices;
  }

  Future<void> registerDevice(DeviceInfo device) async {
    final now = DateTime.now().toUtc();
    final values = {
      'deviceName': device.deviceName,
      'platform': device.platform,
      'notificationsEnabled': device.notificationsEnabled,
      'updatedAt': now,
      'lastSeenAt': now,
      if (device.token != null && device.token!.isNotEmpty)
        'token': device.token,
    };

    if (Platform.isWindows) {
      final response = await http.patch(
        _restUri('users/$roomId/tokens/${Uri.encodeComponent(device.id)}'),
        headers: await _restHeaders(),
        body: jsonEncode({'fields': _restFields(values)}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Device register failed: ${response.body}');
      }
      await _deleteLegacyDeviceDocument(device.id, device.deviceName);
      return;
    }

    await _ensureSignedIn();
    await _tokens.doc(device.id).set({
      'deviceName': device.deviceName,
      'platform': device.platform,
      'notificationsEnabled': device.notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      if (device.token != null && device.token!.isNotEmpty)
        'token': device.token,
    }, SetOptions(merge: true));
    await _deleteLegacyDeviceDocument(device.id, device.deviceName);
  }

  Future<void> addClipboardItem(
    String content,
    String deviceName,
    String platform,
  ) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    final contentHash = await CryptoService.instance.contentHash(content);
    final now = DateTime.now().toUtc();
    final documentId = _clipboardDocumentId(contentHash, now);
    if (await _hasRecentDuplicateContentHash(contentHash)) {
      return;
    }

    if (Platform.isWindows) {
      final encryptedContent = await CryptoService.instance.encrypt(content);
      final deviceId = await DeviceIdentityService.deviceId();
      final response = await http.patch(
        _restUri('users/$roomId/clipboards/${Uri.encodeComponent(documentId)}'),
        headers: await _restHeaders(),
        body: jsonEncode({
          'fields': _restFields({
            'content': encryptedContent,
            'timestamp': now,
            'createdAtClient': now,
            'deviceName': deviceName,
            'platform': platform,
            'deviceId': deviceId,
            'contentHash': contentHash,
            'isPinned': false,
          }),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Clipboard upload failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    final encryptedContent = await CryptoService.instance.encrypt(content);
    final deviceId = await DeviceIdentityService.deviceId();

    await _clipboards.doc(documentId).set({
      'content': encryptedContent,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.fromDate(now),
      'deviceName': deviceName,
      'platform': platform,
      'deviceId': deviceId,
      'contentHash': contentHash,
      'isPinned': false,
    });
  }

  Future<void> togglePin(String id, bool currentState) async {
    if (Platform.isWindows) {
      final response = await http.patch(
        _restUri('users/$roomId/clipboards/$id', const {
          'updateMask.fieldPaths': 'isPinned',
        }),
        headers: await _restHeaders(),
        body: jsonEncode({
          'fields': _restFields({'isPinned': !currentState}),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Pin update failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _clipboards.doc(id).update({'isPinned': !currentState});
  }

  Future<void> saveFcmToken(
    String deviceId,
    String deviceName,
    String token, {
    String platform = 'unknown',
    bool notificationsEnabled = true,
  }) async {
    if (Platform.isWindows) {
      final response = await http.patch(
        _restUri('users/$roomId/tokens/${Uri.encodeComponent(deviceId)}'),
        headers: await _restHeaders(),
        body: jsonEncode({
          'fields': _restFields({
            'deviceName': deviceName,
            'token': token,
            'platform': platform,
            'notificationsEnabled': notificationsEnabled,
            'updatedAt': DateTime.now().toUtc(),
            'lastSeenAt': DateTime.now().toUtc(),
          }),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Token save failed: ${response.body}');
      }
      await _deleteLegacyDeviceDocument(deviceId, deviceName);
      return;
    }

    await _ensureSignedIn();
    await _tokens.doc(deviceId).set({
      'deviceName': deviceName,
      'token': token,
      'platform': platform,
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _deleteLegacyDeviceDocument(deviceId, deviceName);
  }

  Future<void> _deleteLegacyDeviceDocument(
    String deviceId,
    String deviceName,
  ) async {
    final trimmedName = deviceName.trim();
    if (trimmedName.isEmpty || trimmedName == deviceId) return;

    if (Platform.isWindows) {
      final response = await http.delete(
        _restUri('users/$roomId/tokens/${Uri.encodeComponent(trimmedName)}'),
        headers: await _restHeaders(),
      );

      if (response.statusCode == 404) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Legacy device delete failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _tokens.doc(trimmedName).delete();
  }

  Stream<List<DeviceInfo>> watchDevices() async* {
    final currentDeviceId = await DeviceIdentityService.deviceId();

    if (Platform.isWindows) {
      var delaySeconds = 2;
      while (true) {
        try {
          yield await _fetchRestDevices(currentDeviceId);
          delaySeconds = 2;
          await Future<void>.delayed(const Duration(seconds: 5));
        } catch (_) {
          await Future<void>.delayed(Duration(seconds: delaySeconds));
          delaySeconds = (delaySeconds * 2).clamp(2, 20).toInt();
        }
      }
    }

    await _ensureSignedIn();
    yield* _tokens.snapshots().map((snapshot) {
      final devices = snapshot.docs
          .map(
            (doc) => DeviceInfo.fromMap(
              doc.id,
              doc.data(),
              currentDeviceId: currentDeviceId,
            ),
          )
          .toList();

      devices.sort((a, b) {
        if (a.isCurrentDevice) return -1;
        if (b.isCurrentDevice) return 1;
        final aTime =
            a.lastSeenAt ??
            a.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastSeenAt ??
            b.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return devices;
    });
  }

  Future<void> renameCurrentDevice(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final deviceId = await DeviceIdentityService.deviceId();
    await DeviceIdentityService.setDeviceName(trimmed);

    if (Platform.isWindows) {
      final response = await http.patch(
        _restUri(
          'users/$roomId/tokens/${Uri.encodeComponent(deviceId)}',
          const {'updateMask.fieldPaths': 'deviceName'},
        ),
        headers: await _restHeaders(),
        body: jsonEncode({
          'fields': _restFields({'deviceName': trimmed}),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Device rename failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _tokens.doc(deviceId).set({
      'deviceName': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setCurrentDeviceNotifications(bool enabled) async {
    final deviceId = await DeviceIdentityService.deviceId();

    if (Platform.isWindows) {
      final response = await http.patch(
        _restUri(
          'users/$roomId/tokens/${Uri.encodeComponent(deviceId)}',
          const {'updateMask.fieldPaths': 'notificationsEnabled'},
        ),
        headers: await _restHeaders(),
        body: jsonEncode({
          'fields': _restFields({'notificationsEnabled': enabled}),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Notification update failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _tokens.doc(deviceId).set({
      'notificationsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDevice(String deviceId) async {
    if (Platform.isWindows) {
      final response = await http.delete(
        _restUri('users/$roomId/tokens/${Uri.encodeComponent(deviceId)}'),
        headers: await _restHeaders(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Device delete failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _tokens.doc(deviceId).delete();
  }

  Stream<List<ClipboardItem>> get clipboardStream async* {
    if (Platform.isWindows) {
      var delaySeconds = 1;
      while (true) {
        try {
          yield await _fetchRestClipboardItems();
          delaySeconds = 1;
          await Future<void>.delayed(const Duration(seconds: 1));
        } catch (_) {
          await Future<void>.delayed(Duration(seconds: delaySeconds));
          delaySeconds = (delaySeconds * 2).clamp(1, 10).toInt();
        }
      }
    }

    await _ensureSignedIn();

    yield* _clipboards
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final items = <ClipboardItem>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawContent = data['content'] as String? ?? '';
            final decryptedContent = await CryptoService.instance.decrypt(
              rawContent,
            );

            items.add(
              ClipboardItem.fromMap(doc.id, {
                ...data,
                'content': decryptedContent,
              }),
            );
          }

          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        });
  }

  Future<void> deleteItem(String id) async {
    if (Platform.isWindows) {
      final response = await http.delete(
        _restUri('users/$roomId/clipboards/$id'),
        headers: await _restHeaders(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Clipboard delete failed: ${response.body}');
      }
      return;
    }

    await _ensureSignedIn();
    await _clipboards.doc(id).delete();
  }
}

class _RestAuthSession {
  const _RestAuthSession(this.idToken, this.expiresAt);

  final String idToken;
  final DateTime expiresAt;
}
