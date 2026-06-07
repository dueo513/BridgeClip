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
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 34,
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
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: mutedTextColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      iconFor?.call(value) ?? Icons.tune_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, option),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 58),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: option == value
                            ? primaryColor.withValues(alpha: 0.15)
                            : softFillColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: option == value
                              ? primaryColor.withValues(alpha: 0.34)
                              : borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: option == value
                                  ? primaryColor.withValues(alpha: 0.16)
                                  : mutedTextColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              iconFor?.call(option) ?? Icons.check_rounded,
                              color: option == value
                                  ? primaryColor
                                  : mutedTextColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              labelFor(option),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (option == value)
                            Icon(
                              Icons.radio_button_checked_rounded,
                              color: primaryColor,
                              size: 21,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: mutedTextColor.withValues(alpha: 0.45),
                              size: 21,
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
