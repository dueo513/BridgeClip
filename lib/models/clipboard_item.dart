class ClipboardItem {
  final String id;
  final String content;
  final DateTime timestamp;
  final String deviceName;
  final String platform;
  final String? deviceId;
  final String? contentHash;
  final bool isPinned;

  ClipboardItem({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.deviceName,
    required this.platform,
    this.deviceId,
    this.contentHash,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'deviceName': deviceName,
      'platform': platform,
      'deviceId': deviceId,
      'contentHash': contentHash,
      'isPinned': isPinned,
    };
  }

  factory ClipboardItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime readTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;

      final dynamic toDate = value;
      try {
        return toDate.toDate() as DateTime;
      } catch (_) {
        return DateTime.tryParse(value.toString()) ?? DateTime.now();
      }
    }

    return ClipboardItem(
      id: id,
      content: map['content'] ?? '',
      timestamp: readTimestamp(map['timestamp'] ?? map['createdAtClient']),
      deviceName: map['deviceName'] ?? 'Unknown Device',
      platform: map['platform'] ?? 'unknown',
      deviceId: map['deviceId'] as String?,
      contentHash: map['contentHash'] as String?,
      isPinned: map['isPinned'] == true,
    );
  }
}
