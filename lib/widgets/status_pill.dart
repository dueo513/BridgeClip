import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.text,
    required this.primaryColor,
    required this.textColor,
    this.color,
    this.label,
  });

  final IconData icon;
  final String text;
  final Color primaryColor;
  final Color textColor;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? primaryColor;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.56),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
