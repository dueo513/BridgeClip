import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../services/localization.dart';
import '../services/platform_service.dart';
import 'device_row.dart';
import 'header_action_button.dart';
import 'overview_header.dart';
import 'settings_check_card.dart';
import 'status_pill.dart';

class DeviceManagementBody extends StatelessWidget {
  const DeviceManagementBody({
    super.key,
    required this.roomId,
    required this.deviceStream,
    required this.lang,
    required this.currentDeviceId,
    required this.notificationsEnabled,
    required this.appLockEnabled,
    required this.launchAtStartupEnabled,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onConnectDevice,
    required this.onRenameCurrentDevice,
    required this.onRemoveDevice,
    required this.onCurrentDeviceNotificationsChanged,
  });

  final String roomId;
  final Stream<List<DeviceInfo>> deviceStream;
  final AppLang lang;
  final String? currentDeviceId;
  final bool notificationsEnabled;
  final bool appLockEnabled;
  final bool? launchAtStartupEnabled;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onConnectDevice;
  final VoidCallback onRenameCurrentDevice;
  final ValueChanged<DeviceInfo> onRemoveDevice;
  final ValueChanged<bool> onCurrentDeviceNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DeviceInfo>>(
      stream: deviceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: textColor),
            ),
          );
        }

        final devices = snapshot.data ?? const <DeviceInfo>[];
        final currentDevice = _currentDevice(devices);

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            OverviewHeader(
              icon: Icons.devices_rounded,
              title: LocalizationService.get('device_management'),
              subtitle:
                  '${LocalizationService.get('room_short_label')} ${_compactRoomId(roomId)}',
              pills: [
                StatusPill(
                  icon: Icons.devices_other_rounded,
                  text: LocalizationService.getFormatted('devices_count', [
                    '${devices.length}',
                  ]),
                  primaryColor: primaryColor,
                  textColor: textColor,
                ),
                StatusPill(
                  icon: Icons.cloud_done_rounded,
                  text: LocalizationService.get('sync_ready'),
                  primaryColor: primaryColor,
                  textColor: textColor,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
              primaryColor: primaryColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              trailing: HeaderActionButton(
                icon: Icons.qr_code_rounded,
                label: LocalizationService.get('connect_new_device'),
                onPressed: onConnectDevice,
                primaryColor: primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                LocalizationService.get('connected_devices'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  LocalizationService.get('empty_devices'),
                  style: TextStyle(color: mutedTextColor),
                ),
              )
            else
              for (final device in devices)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _deviceRow(device),
                ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _settingsCheckCard(currentDevice),
            ),
          ],
        );
      },
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

  Widget _settingsCheckCard(DeviceInfo? currentDevice) {
    final deviceId = currentDeviceId ?? currentDevice?.id;
    final platform = currentDevice?.platform ?? PlatformService.platformName();
    final hasPushToken =
        currentDevice?.token != null && currentDevice!.token!.isNotEmpty;
    final notificationsOn =
        currentDevice?.notificationsEnabled ?? notificationsEnabled;

    return SettingsCheckCard(
      roomId: roomId,
      deviceId: deviceId,
      platform: platform,
      hasPushToken: hasPushToken,
      notificationsOn: notificationsOn,
      appLockEnabled: appLockEnabled,
      launchAtStartupEnabled: launchAtStartupEnabled,
      primaryColor: primaryColor,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      textColor: textColor,
      mutedTextColor: mutedTextColor,
    );
  }

  Widget _deviceRow(DeviceInfo device) {
    return DeviceRow(
      device: device,
      lang: lang,
      primaryColor: primaryColor,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      textColor: textColor,
      mutedTextColor: mutedTextColor,
      onRename: onRenameCurrentDevice,
      onRemove: () => onRemoveDevice(device),
      onNotificationsChanged: onCurrentDeviceNotificationsChanged,
    );
  }

  String _compactRoomId(String roomId) {
    if (roomId.length <= 18) return roomId;
    return '${roomId.substring(0, 11)}...${roomId.substring(roomId.length - 4)}';
  }
}
