import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const appId = '77V8QWTSSU';
  const adminKey = 'f33148bed3d625099bf74c1a728b5774';
  const indexName = 'products';

  final url = Uri.parse('https://$appId.algolia.net/1/indexes/$indexName/batch');
  
  print('Testing URL: $url');

  final headers = {
    'X-Algolia-Application-Id': appId,
    'X-Algolia-API-Key': adminKey,
    'Content-Type': 'application/json',
  };

  final body = {
    'requests': [
      {
        'action': 'updateObject',
        'body': {
          'objectID': 'test1',
          'name': 'Test'
        }
      }
    ]
  };

  try {
    final res = await http.post(url, headers: headers, body: jsonEncode(body));
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }
}
