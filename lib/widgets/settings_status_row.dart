import 'package:flutter/material.dart';

class SettingsStatusRow extends StatelessWidget {
  const SettingsStatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isOk,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isOk;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final color = isOk ? primaryColor : Colors.amber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: mutedTextColor, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (helper != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    helper!,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.45),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            isOk ? Icons.check_circle : Icons.warning_amber_rounded,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}
