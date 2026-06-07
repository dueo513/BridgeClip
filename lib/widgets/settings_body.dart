import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../services/localization.dart';
import '../services/platform_service.dart';
import '../services/theme_service.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({
    super.key,
    required this.roomId,
    required this.deviceStream,
    required this.lang,
    required this.currentDeviceId,
    required this.notificationsEnabled,
    required this.autoDeleteMinutes,
    required this.appLockEnabled,
    required this.launchAtStartupEnabled,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onConnectDevice,
    required this.onShowLanguage,
    required this.onToggleTheme,
    required this.onToggleNotifications,
    required this.onShowAutoDelete,
    required this.onShowAppLock,
    required this.onToggleLaunchAtStartup,
    required this.onCopyRoomId,
    required this.onLogout,
  });

  final String roomId;
  final Stream<List<DeviceInfo>> deviceStream;
  final AppLang lang;
  final String? currentDeviceId;
  final bool notificationsEnabled;
  final int autoDeleteMinutes;
  final bool appLockEnabled;
  final bool? launchAtStartupEnabled;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onConnectDevice;
  final VoidCallback onShowLanguage;
  final FutureOr<void> Function() onToggleTheme;
  final FutureOr<void> Function() onToggleNotifications;
  final VoidCallback onShowAutoDelete;
  final VoidCallback onShowAppLock;
  final FutureOr<void> Function(bool value) onToggleLaunchAtStartup;
  final VoidCallback onCopyRoomId;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DeviceInfo>>(
      stream: deviceStream,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const <DeviceInfo>[];
        final currentDevice = _currentDevice(devices);
        final notificationsOn =
            currentDevice?.notificationsEnabled ?? notificationsEnabled;

        return ListView(
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            _pageTitle(),
            _section(
              title: LocalizationService.get('settings_general'),
              children: [
                _actionTile(
                  icon: Icons.language_rounded,
                  title: LocalizationService.get('language_title'),
                  value: lang == AppLang.ko
                      ? LocalizationService.get('language_ko')
                      : LocalizationService.get('language_en'),
                  onTap: onShowLanguage,
                ),
                _switchTile(
                  icon: AppThemeService.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: LocalizationService.get('settings_theme'),
                  value: AppThemeService.isDark,
                  onChanged: (_) => onToggleTheme(),
                  valueText: AppThemeService.isDark
                      ? LocalizationService.get('theme_dark')
                      : LocalizationService.get('theme_light'),
                ),
                _switchTile(
                  icon: notificationsOn
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  title: LocalizationService.get('status_notifications'),
                  value: notificationsOn,
                  onChanged: (_) => onToggleNotifications(),
                  valueText: notificationsOn
                      ? LocalizationService.get('status_on')
                      : LocalizationService.get('status_off'),
                ),
                _actionTile(
                  icon: Icons.timer_rounded,
                  title: LocalizationService.get('timer_title'),
                  value: _autoDeleteLabel(),
                  onTap: onShowAutoDelete,
                ),
              ],
            ),
            _section(
              title: LocalizationService.get('settings_security'),
              children: [
                _actionTile(
                  icon: appLockEnabled ? Icons.lock : Icons.lock_open,
                  title: LocalizationService.get('app_lock_title'),
                  value: appLockEnabled
                      ? LocalizationService.get('status_on')
                      : LocalizationService.get('status_off'),
                  onTap: onShowAppLock,
                ),
              ],
            ),
            _section(
              title: LocalizationService.get('settings_connection'),
              children: [
                _actionTile(
                  icon: Icons.meeting_room_rounded,
                  title: LocalizationService.get('status_room'),
                  value: roomId,
                  onTap: onCopyRoomId,
                ),
                _actionTile(
                  icon: Icons.qr_code_rounded,
                  title: LocalizationService.get('connect_new_device'),
                  value: LocalizationService.get('settings_open'),
                  onTap: onConnectDevice,
                ),
                if (PlatformService.isDesktop)
                  _switchTile(
                    icon: Icons.rocket_launch_rounded,
                    title: LocalizationService.get('status_auto_start'),
                    value: launchAtStartupEnabled ?? false,
                    onChanged: onToggleLaunchAtStartup,
                    valueText: launchAtStartupEnabled == null
                        ? LocalizationService.get('status_checking')
                        : launchAtStartupEnabled!
                        ? LocalizationService.get('status_on')
                        : LocalizationService.get('status_off'),
                  ),
              ],
            ),
            _section(
              title: LocalizationService.get('settings_account'),
              children: [
                _actionTile(
                  icon: Icons.logout_rounded,
                  title: LocalizationService.get('logout_title'),
                  value: LocalizationService.get('btn_logout'),
                  onTap: onLogout,
                  danger: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _pageTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.get('settings'),
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${LocalizationService.get('room_short_label')} ${_compactRoomId(roomId)}',
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                title,
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final accent = danger ? Colors.redAccent : primaryColor;
    return ListTile(
      leading: Icon(icon, color: accent),
      title: Text(
        title,
        style: TextStyle(color: danger ? Colors.redAccent : textColor),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: mutedTextColor),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: mutedTextColor),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String valueText,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: value ? primaryColor : mutedTextColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(valueText, style: TextStyle(color: mutedTextColor)),
      value: value,
      activeThumbColor: primaryColor,
      onChanged: onChanged,
    );
  }

  DeviceInfo? _currentDevice(List<DeviceInfo> devices) {
    for (final device in devices) {
      if ((currentDeviceId != null && device.id == currentDeviceId) ||
          device.isCurrentDevice) {
        return device;
      }
    }
    return null;
  }

  String _autoDeleteLabel() {
    return switch (autoDeleteMinutes) {
      0 => LocalizationService.get('timer_keep_forever'),
      1 => LocalizationService.get('timer_1m'),
      10 => LocalizationService.get('timer_10m'),
      60 => LocalizationService.get('timer_1h'),
      1440 => LocalizationService.get('timer_1d'),
      _ => LocalizationService.getFormatted('timer_minutes_short', [
        '$autoDeleteMinutes',
      ]),
    };
  }

  String _compactRoomId(String roomId) {
    if (roomId.length <= 18) return roomId;
    return '${roomId.substring(0, 11)}...${roomId.substring(roomId.length - 4)}';
  }
}
