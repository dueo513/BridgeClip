class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.deviceName,
    required this.platform,
    this.token,
    this.notificationsEnabled = true,
    this.updatedAt,
    this.lastSeenAt,
    this.isCurrentDevice = false,
  });

  final String id;
  final String deviceName;
  final String platform;
  final String? token;
  final bool notificationsEnabled;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final bool isCurrentDevice;

  DeviceInfo copyWith({
    String? id,
    String? deviceName,
    String? platform,
    String? token,
    bool? notificationsEnabled,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    bool? isCurrentDevice,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      token: token ?? this.token,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
    );
  }

  factory DeviceInfo.fromMap(
    String id,
    Map<String, dynamic> map, {
    String? currentDeviceId,
  }) {
    DateTime? readTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;

      final dynamic toDate = value;
      try {
        return toDate.toDate() as DateTime;
      } catch (_) {
        return DateTime.tryParse(value.toString());
      }
    }

    return DeviceInfo(
      id: id,
      deviceName: map['deviceName'] ?? id,
      platform: map['platform'] ?? 'unknown',
      token: map['token'] as String?,
      notificationsEnabled: map['notificationsEnabled'] != false,
      updatedAt: readTimestamp(map['updatedAt']),
      lastSeenAt: readTimestamp(map['lastSeenAt']),
      isCurrentDevice: currentDeviceId == id,
    );
  }
}
