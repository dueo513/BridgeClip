import 'package:flutter/material.dart';

import '../services/localization.dart';

class AutoDeleteTimerDialog extends StatelessWidget {
  const AutoDeleteTimerDialog({
    super.key,
    required this.selectedMinutes,
    required this.onSelected,
  });

  final int selectedMinutes;
  final ValueChanged<AutoDeleteTimerChoice> onSelected;

  static const choices = [
    AutoDeleteTimerChoice('timer_keep_forever', 0),
    AutoDeleteTimerChoice('timer_1m', 1),
    AutoDeleteTimerChoice('timer_10m', 10),
    AutoDeleteTimerChoice('timer_1h', 60),
    AutoDeleteTimerChoice('timer_1d', 1440),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        LocalizationService.get('timer_title'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in choices) _timerOption(context, choice),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            LocalizationService.get('close'),
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _timerOption(BuildContext context, AutoDeleteTimerChoice choice) {
    final isSelected = selectedMinutes == choice.minutes;
    return ListTile(
      title: Text(
        choice.label,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white70,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blueAccent)
          : null,
      onTap: () => onSelected(choice),
    );
  }
}

class AutoDeleteTimerChoice {
  const AutoDeleteTimerChoice(this.labelKey, this.minutes);

  final String labelKey;
  final int minutes;

  String get label => LocalizationService.get(labelKey);
}
