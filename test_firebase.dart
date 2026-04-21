import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyBmX9bvfS6B8tDeu24bW77nREiAdu7SBoU';
  final projectId = 'shrud-clip-2026-78fee';
  final roomId = '777';
  final baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$roomId/clipboards';
  final url = '$baseUrl?key=$apiKey';
  print('Hitting $url');
  
  final body = jsonEncode({
    'fields': {
      'content': {'stringValue': 'AI TEST'},
      'timestamp': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'deviceName': {'stringValue': 'AI'},
      'platform': {'stringValue': 'windows'},
      'isPinned': {'booleanValue': false},
    }
  });

  try {
    final res = await http.post(Uri.parse(url), body: body);
    print('Code: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Exception: $e');
  }
}
