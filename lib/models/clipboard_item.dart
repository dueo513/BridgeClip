class ClipboardItem {
  final String id;
  final String content;
  final DateTime timestamp;
  final String deviceName;
  final String platform;
  final bool isPinned;

  ClipboardItem({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.deviceName,
    required this.platform,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'deviceName': deviceName,
      'platform': platform,
      'isPinned': isPinned,
    };
  }

  factory ClipboardItem.fromMap(String id, Map<String, dynamic> map) {
    return ClipboardItem(
      id: id,
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'].toString()) : DateTime.now(),
      deviceName: map['deviceName'] ?? 'Unknown Device',
      platform: map['platform'] ?? 'unknown',
      isPinned: map['isPinned'] == true,
    );
  }
}

