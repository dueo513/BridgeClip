import 'package:flutter/material.dart';

import '../services/localization.dart';

class LockedScaffold extends StatelessWidget {
  const LockedScaffold({
    super.key,
    required this.pinController,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onUnlock,
  });

  final TextEditingController pinController;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: primaryColor,
                    size: 44,
                  ),
                ),
                Text(
                  LocalizationService.get('app_locked_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  LocalizationService.get('app_locked_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedTextColor, fontSize: 14),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: pinController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 12,
                  onSubmitted: (_) => onUnlock(),
                  style: TextStyle(color: textColor, letterSpacing: 6),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: LocalizationService.get('pin_hint'),
                    hintStyle: TextStyle(color: mutedTextColor),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.lock_open),
                  label: Text(LocalizationService.get('unlock')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
