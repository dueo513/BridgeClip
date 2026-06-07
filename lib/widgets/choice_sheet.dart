import 'package:flutter/material.dart';

class ChoiceSheet<T> extends StatelessWidget {
  const ChoiceSheet({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.primaryColor,
    required this.surfaceColor,
    required this.softFillColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    this.iconFor,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T value) labelFor;
  final IconData Function(T value)? iconFor;
  final Color primaryColor;
  final Color surfaceColor;
  final Color softFillColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: mutedTextColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, option),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: option == value
                            ? primaryColor.withValues(alpha: 0.13)
                            : softFillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: option == value
                              ? primaryColor.withValues(alpha: 0.24)
                              : borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            iconFor?.call(option) ?? Icons.check_rounded,
                            color: option == value
                                ? primaryColor
                                : mutedTextColor,
                            size: 21,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              labelFor(option),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (option == value)
                            Icon(
                              Icons.check_circle_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
