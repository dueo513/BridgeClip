import 'dart:convert';
import 'package:http/http.dart' as http;
void main() async {
  print('Fetching...');
  final res = await http.get(Uri.parse('https://firestore.googleapis.com/v1/projects/shrud-clip-2026-78fee/databases/(default)/documents/users/unknown_user/clipboards'));
  print(res.statusCode);
  print(res.body);
}

