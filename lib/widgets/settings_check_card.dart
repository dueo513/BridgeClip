import 'package:flutter/material.dart';

import '../services/localization.dart';
import '../services/platform_service.dart';
import 'settings_status_row.dart';

class SettingsCheckCard extends StatelessWidget {
  const SettingsCheckCard({
    super.key,
    required this.roomId,
    required this.deviceId,
    required this.platform,
    required this.hasPushToken,
    required this.notificationsOn,
    required this.appLockEnabled,
    required this.launchAtStartupEnabled,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
  });

  final String roomId;
  final String? deviceId;
  final String platform;
  final bool hasPushToken;
  final bool notificationsOn;
  final bool appLockEnabled;
  final bool? launchAtStartupEnabled;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;

  @override
  Widget build(BuildContext context) {
    final isMobilePushPlatform = platform == 'android' || platform == 'ios';

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                LocalizationService.get('settings_check'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            LocalizationService.get('settings_check_desc'),
            style: TextStyle(color: mutedTextColor, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          _statusRow(
            icon: Icons.meeting_room_rounded,
            label: LocalizationService.get('status_room'),
            value: roomId,
            isOk: roomId.trim().isNotEmpty,
          ),
          _statusRow(
            icon: _deviceIcon(platform),
            label: LocalizationService.get('status_device_id'),
            value: deviceId ?? LocalizationService.get('unknown'),
            isOk: deviceId != null && deviceId!.isNotEmpty,
          ),
          _statusRow(
            icon: Icons.devices_rounded,
            label: LocalizationService.get('status_platform'),
            value: platform,
            isOk: platform != 'unknown',
          ),
          _statusRow(
            icon: notificationsOn
                ? Icons.notifications_active
                : Icons.notifications_off,
            label: LocalizationService.get('status_notifications'),
            value: notificationsOn
                ? LocalizationService.get('status_on')
                : LocalizationService.get('status_off'),
            isOk: notificationsOn,
            helper: notificationsOn
                ? null
                : LocalizationService.get('status_notifications_hint'),
          ),
          _statusRow(
            icon: Icons.token_rounded,
            label: LocalizationService.get('status_push_token'),
            value: isMobilePushPlatform
                ? (hasPushToken
                      ? LocalizationService.get('status_available')
                      : LocalizationService.get('status_missing'))
                : LocalizationService.get('status_not_needed'),
            isOk: !isMobilePushPlatform || hasPushToken,
            helper: !isMobilePushPlatform
                ? LocalizationService.get('status_push_token_desktop_hint')
                : hasPushToken
                ? null
                : LocalizationService.get('status_push_token_hint'),
          ),
          _statusRow(
            icon: appLockEnabled ? Icons.lock : Icons.lock_open,
            label: LocalizationService.get('status_app_lock'),
            value: appLockEnabled
                ? LocalizationService.get('status_on')
                : LocalizationService.get('status_off'),
            isOk: true,
            helper: appLockEnabled
                ? LocalizationService.get('status_app_lock_hint')
                : null,
          ),
          _statusRow(
            icon: Icons.rocket_launch_rounded,
            label: LocalizationService.get('status_auto_start'),
            value: PlatformService.isDesktop
                ? (launchAtStartupEnabled == null
                      ? LocalizationService.get('status_checking')
                      : launchAtStartupEnabled!
                      ? LocalizationService.get('status_on')
                      : LocalizationService.get('status_off'))
                : LocalizationService.get('status_not_needed'),
            isOk: !PlatformService.isDesktop || launchAtStartupEnabled != false,
            helper: PlatformService.isDesktop && launchAtStartupEnabled == false
                ? LocalizationService.get('status_auto_start_hint')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isOk,
    String? helper,
  }) {
    return SettingsStatusRow(
      icon: icon,
      label: label,
      value: value,
      isOk: isOk,
      primaryColor: primaryColor,
      textColor: textColor,
      mutedTextColor: mutedTextColor,
      helper: helper,
    );
  }

  IconData _deviceIcon(String platform) {
    if (platform == 'macos') return Icons.laptop_mac;
    if (platform == 'windows') return Icons.computer;
    if (platform == 'ios') return Icons.phone_iphone;
    if (platform == 'android') return Icons.phone_android;
    return Icons.devices;
  }
}
