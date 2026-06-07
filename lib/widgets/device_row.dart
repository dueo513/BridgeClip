import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/device_info.dart';
import '../services/localization.dart';

class DeviceRow extends StatelessWidget {
  const DeviceRow({
    super.key,
    required this.device,
    required this.lang,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onRename,
    required this.onRemove,
  });

  final DeviceInfo device;
  final AppLang lang;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lastSeen = device.lastSeenAt ?? device.updatedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_deviceIcon(device.platform), color: primaryColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device.deviceName,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (device.isCurrentDevice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  LocalizationService.get('current_device'),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.platform,
                style: TextStyle(color: mutedTextColor, fontSize: 12),
              ),
              if (lastSeen != null)
                Text(
                  '${LocalizationService.get('last_seen')} ${timeago.format(lastSeen, locale: lang == AppLang.ko ? 'ko' : 'en')}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        trailing: device.isCurrentDevice
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: LocalizationService.get('rename_device'),
                    icon: Icon(Icons.edit, color: mutedTextColor),
                    onPressed: onRename,
                  ),
                  IconButton(
                    tooltip: LocalizationService.get('remove_device'),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: onRemove,
                  ),
                ],
              )
            : IconButton(
                tooltip: LocalizationService.get('remove_device'),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onRemove,
              ),
      ),
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
