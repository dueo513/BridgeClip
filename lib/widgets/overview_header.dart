import 'package:flutter/material.dart';

class OverviewHeader extends StatelessWidget {
  const OverviewHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pills,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    this.trailing,
    this.pillsLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> pills;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final Widget? trailing;
  final String? pillsLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    surfaceColor,
                    primaryColor.withValues(alpha: 0.16),
                    Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.10),
                  ]
                : [
                    Colors.white,
                    primaryColor.withValues(alpha: 0.10),
                    Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.08),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.07),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: primaryColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            if (pills.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (pillsLabel != null) ...[
                Text(
                  pillsLabel!,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(spacing: 8, runSpacing: 8, children: pills),
            ],
          ],
        ),
      ),
    );
  }
}
