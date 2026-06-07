import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../services/localization.dart';
import 'device_row.dart';

class DeviceManagementBody extends StatelessWidget {
  const DeviceManagementBody({
    super.key,
    required this.roomId,
    required this.deviceStream,
    required this.lang,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onRenameCurrentDevice,
    required this.onRemoveDevice,
  });

  final String roomId;
  final Stream<List<DeviceInfo>> deviceStream;
  final AppLang lang;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onRenameCurrentDevice;
  final ValueChanged<DeviceInfo> onRemoveDevice;

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

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _pageTitle(devices.length),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
          ],
        );
      },
    );
  }

  Widget _pageTitle(int deviceCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.get('device_management'),
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryColor.withValues(alpha: 0.24)),
            ),
            child: Text(
              LocalizationService.getFormatted('devices_count', [
                '$deviceCount',
              ]),
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
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
    );
  }

  String _compactRoomId(String roomId) {
    if (roomId.length <= 18) return roomId;
    return '${roomId.substring(0, 11)}...${roomId.substring(roomId.length - 4)}';
  }
}
