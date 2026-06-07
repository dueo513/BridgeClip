import 'package:flutter/material.dart';

class TopIconButton extends StatelessWidget {
  const TopIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.primaryColor,
    required this.mutedTextColor,
    required this.softFillColor,
    required this.borderColor,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color mutedTextColor;
  final Color softFillColor;
  final Color borderColor;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = danger
        ? Colors.redAccent
        : active
        ? primaryColor
        : mutedTextColor;
    final fillColor = danger
        ? Colors.redAccent.withValues(alpha: isDark ? 0.16 : 0.10)
        : active
        ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.14)
        : softFillColor;
    final strokeColor = danger
        ? Colors.redAccent.withValues(alpha: 0.34)
        : active
        ? primaryColor.withValues(alpha: 0.42)
        : borderColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: strokeColor),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
        ),
      ),
    );
  }
}
