import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/localization.dart';
import 'pin_field.dart';

class AppLockDialogs {
  const AppLockDialogs._();

  static void show({
    required BuildContext context,
    required bool isEnabled,
    required VoidCallback onLockNow,
    required VoidCallback onEnabled,
    required VoidCallback onDisabled,
  }) {
    if (isEnabled) {
      _showManageDialog(
        context: context,
        onLockNow: onLockNow,
        onDisabled: onDisabled,
      );
    } else {
      _showEnableDialog(context: context, onEnabled: onEnabled);
    }
  }

  static void _showManageDialog({
    required BuildContext context,
    required VoidCallback onLockNow,
    required VoidCallback onDisabled,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          LocalizationService.get('app_lock_title'),
          style: const TextStyle(color: Colors.white),
        ),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blueAccent),
              title: Text(
                LocalizationService.get('lock_now'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                onLockNow();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pin, color: Colors.white70),
              title: Text(
                LocalizationService.get('change_pin'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _showChangeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_open, color: Colors.redAccent),
              title: Text(
                LocalizationService.get('disable_app_lock'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                _showDisableDialog(context: context, onDisabled: onDisabled);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              LocalizationService.get('close'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  static void _showEnableDialog({
    required BuildContext context,
    required VoidCallback onEnabled,
  }) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          LocalizationService.get('set_pin_title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PinField(
              controller: pinController,
              hint: LocalizationService.get('pin_hint'),
            ),
            const SizedBox(height: 12),
            PinField(
              controller: confirmController,
              hint: LocalizationService.get('pin_confirm_hint'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              LocalizationService.get('cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();
              if (!_isValidPin(pin) || pin != confirm) {
                _showError(context, 'app_lock_pin_mismatch');
                return;
              }

              await AppLockService.enable(pin);
              if (!context.mounted) return;
              onEnabled();
              Navigator.pop(dialogContext);
              _showSnack(context, 'app_lock_enabled');
            },
            child: Text(
              LocalizationService.get('ok'),
              style: const TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      pinController.dispose();
      confirmController.dispose();
    });
  }

  static void _showChangeDialog(BuildContext context) {
    final currentController = TextEditingController();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          LocalizationService.get('change_pin'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PinField(
              controller: currentController,
              hint: LocalizationService.get('current_pin_hint'),
            ),
            const SizedBox(height: 12),
            PinField(
              controller: pinController,
              hint: LocalizationService.get('new_pin_hint'),
            ),
            const SizedBox(height: 12),
            PinField(
              controller: confirmController,
              hint: LocalizationService.get('pin_confirm_hint'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              LocalizationService.get('cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final current = currentController.text.trim();
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();
              final isCurrentValid = await AppLockService.verify(current);
              if (!context.mounted) return;
              if (!isCurrentValid) {
                _showError(context, 'app_lock_wrong_pin');
                return;
              }
              if (!_isValidPin(pin) || pin != confirm) {
                _showError(context, 'app_lock_pin_mismatch');
                return;
              }

              await AppLockService.enable(pin);
              if (!context.mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _showSnack(context, 'pin_changed');
            },
            child: Text(
              LocalizationService.get('ok'),
              style: const TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      currentController.dispose();
      pinController.dispose();
      confirmController.dispose();
    });
  }

  static void _showDisableDialog({
    required BuildContext context,
    required VoidCallback onDisabled,
  }) {
    final pinController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          LocalizationService.get('disable_app_lock'),
          style: const TextStyle(color: Colors.white),
        ),
        content: PinField(
          controller: pinController,
          hint: LocalizationService.get('current_pin_hint'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              LocalizationService.get('cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final isValid = await AppLockService.verify(
                pinController.text.trim(),
              );
              if (!context.mounted) return;
              if (!isValid) {
                _showError(context, 'app_lock_wrong_pin');
                return;
              }

              await AppLockService.disable();
              if (!context.mounted || !dialogContext.mounted) return;
              onDisabled();
              Navigator.pop(dialogContext);
              _showSnack(context, 'app_lock_disabled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(LocalizationService.get('disable_app_lock')),
          ),
        ],
      ),
    ).whenComplete(pinController.dispose);
  }

  static bool _isValidPin(String pin) {
    return RegExp(r'^\d{4,12}$').hasMatch(pin);
  }

  static void _showError(BuildContext context, String key) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.get(key)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  static void _showSnack(BuildContext context, String key) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.get(key)),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
