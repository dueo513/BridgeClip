import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ClipboardTest());
  }
}

class ClipboardTest extends StatefulWidget {
  const ClipboardTest({super.key});
  @override
  State<ClipboardTest> createState() => _ClipboardTestState();
}

class _ClipboardTestState extends State<ClipboardTest> {
  String _lastCopied = '';

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        String text = data.text!;
        if (text != _lastCopied) {
          print('? CLIPBOARD CHANGED: $text');
          _lastCopied = text;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Copied: $_lastCopied')));
  }
}
