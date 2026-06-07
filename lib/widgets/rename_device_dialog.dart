import 'package:flutter/material.dart';

import '../services/localization.dart';

class RenameDeviceDialog extends StatefulWidget {
  const RenameDeviceDialog({
    super.key,
    required this.initialName,
    required this.onRename,
  });

  final String initialName;
  final Future<void> Function(String name) onRename;

  @override
  State<RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<RenameDeviceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        LocalizationService.get('device_rename_title'),
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: LocalizationService.get('device_name_hint'),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            LocalizationService.get('cancel'),
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: () async {
            final newName = _controller.text.trim();
            if (newName.isEmpty) return;
            await widget.onRename(newName);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(
            LocalizationService.get('ok'),
            style: const TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
