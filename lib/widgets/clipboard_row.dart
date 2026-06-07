import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/clipboard_item.dart';
import '../services/localization.dart';

class ClipboardRow extends StatelessWidget {
  const ClipboardRow({
    super.key,
    required this.item,
    required this.lang,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onCopy,
    required this.onTogglePin,
    required this.onDelete,
  });

  final ClipboardItem item;
  final AppLang lang;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onCopy;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_deviceIcon(item.platform), color: primaryColor),
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              item.content,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.32,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                item.deviceName,
                style: TextStyle(color: mutedTextColor, fontSize: 12),
              ),
              Text(
                item.platform,
                style: TextStyle(color: mutedTextColor, fontSize: 12),
              ),
              Text(
                timeago.format(
                  item.timestamp,
                  locale: lang == AppLang.ko ? 'ko' : 'en',
                ),
                style: TextStyle(color: mutedTextColor, fontSize: 12),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.copy, color: mutedTextColor),
                onPressed: onCopy,
              ),
              IconButton(
                icon: Icon(
                  item.isPinned ? Icons.unarchive : Icons.archive,
                  color: item.isPinned ? primaryColor : mutedTextColor,
                ),
                onPressed: onTogglePin,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
            ],
          ),
          onTap: onCopy,
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
