import 'dart:convert';
import 'package:http/http.dart' as http;
void main() async {
  print('Posting...');
  final body = jsonEncode({
    'fields': {
      'content': {'stringValue': 'Test Copy from CLI'},
      'timestamp': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'deviceName': {'stringValue': 'CLI'},
      'platform': {'stringValue': 'windows'}
    }
  });
  final uri = Uri.parse('https://firestore.googleapis.com/v1/projects/shrud-clip-2026-78fee/databases/(default)/documents/users/unknown_user/clipboards?key=AIzaSyBmX9bvfS6B8tDeu24bW77nREiAdu7SBoU');
  final res = await http.post(uri, body: body, headers: {'Content-Type': 'application/json'});
  print(res.statusCode);
  print(res.body);

  print('Fetching...');
  final res2 = await http.get(uri);
  print(res2.statusCode);
  print(res2.body);
}

