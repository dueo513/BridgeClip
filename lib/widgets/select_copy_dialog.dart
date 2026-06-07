import 'package:flutter/material.dart';

import '../services/localization.dart';

class SelectCopyDialog extends StatefulWidget {
  const SelectCopyDialog({super.key, required this.text, required this.onCopy});

  final String text;
  final ValueChanged<String> onCopy;

  @override
  State<SelectCopyDialog> createState() => _SelectCopyDialogState();
}

class _SelectCopyDialogState extends State<SelectCopyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
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
        LocalizationService.get('select_copy_title'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.black.withValues(alpha: 0.2),
          filled: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            LocalizationService.get('close'),
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onCopy(_controller.text);
            Navigator.pop(context);
          },
          child: Text(
            LocalizationService.get('copy_selected'),
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
