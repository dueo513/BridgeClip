import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/localization.dart';

class ConnectDeviceSheet extends StatelessWidget {
  const ConnectDeviceSheet({
    super.key,
    required this.roomId,
    required this.link,
    required this.primaryColor,
    required this.surfaceColor,
    required this.softFillColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onCopyRoomId,
    required this.onCopyLink,
  });

  final String roomId;
  final String link;
  final Color primaryColor;
  final Color surfaceColor;
  final Color softFillColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onCopyRoomId;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = media.size.height < 720;
    final qrSize = isCompact ? 148.0 : 190.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(18, 10, 18, isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: EdgeInsets.only(bottom: isCompact ? 10 : 16),
                  decoration: BoxDecoration(
                    color: mutedTextColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.qr_code_rounded, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.get('connect_new_device'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          LocalizationService.get('connect_new_device_desc'),
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: isCompact ? 11 : 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 12 : 18),
              Center(
                child: Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    size: qrSize,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF111827),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 12 : 18),
              _ConnectionInfoRow(
                icon: Icons.meeting_room_rounded,
                label: LocalizationService.get('room_id_label'),
                value: roomId,
                primaryColor: primaryColor,
                softFillColor: softFillColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
                onCopy: onCopyRoomId,
              ),
              const SizedBox(height: 10),
              _ConnectionInfoRow(
                icon: Icons.link_rounded,
                label: LocalizationService.get('connection_link'),
                value: link,
                primaryColor: primaryColor,
                softFillColor: softFillColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
                onCopy: onCopyLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionInfoRow extends StatelessWidget {
  const _ConnectionInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
    required this.softFillColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;
  final Color softFillColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: softFillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: LocalizationService.get('copy'),
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, color: mutedTextColor),
          ),
        ],
      ),
    );
  }
}
