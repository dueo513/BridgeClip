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
    final accent = danger
        ? Colors.redAccent
        : active
        ? primaryColor
        : mutedTextColor;

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
              color: active
                  ? primaryColor.withValues(alpha: 0.13)
                  : softFillColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? primaryColor.withValues(alpha: 0.22)
                    : borderColor,
              ),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
        ),
      ),
    );
  }
}
