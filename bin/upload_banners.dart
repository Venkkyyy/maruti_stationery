import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String projectId = 'maruti-stationery-d7862';
const String cloudinaryCloudName = 'eizhyg2w';
const String cloudinaryUploadPreset = 'maruti_preset';

Future<void> main() async {
  print('Starting banner upload script...');

  // 1. Fetch existing banners
  print('Fetching existing banners from Firestore...');
  final listUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/banners');
  final listResponse = await http.get(listUrl);
  
  if (listResponse.statusCode == 200) {
    final listData = jsonDecode(listResponse.body);
    if (listData['documents'] != null) {
      final List documents = listData['documents'];
      print('Found ${documents.length} existing banners. Deleting them...');
      for (final doc in documents) {
        final String name = doc['name']; // Format: projects/.../databases/(default)/documents/banners/ID
        final deleteUrl = Uri.parse('https://firestore.googleapis.com/v1/$name');
        final deleteResponse = await http.delete(deleteUrl);
        if (deleteResponse.statusCode == 200) {
          print('Deleted banner: $name');
        } else {
          print('Failed to delete banner: $name, status: ${deleteResponse.statusCode}');
        }
      }
    } else {
      print('No existing banners found in Firestore.');
    }
  } else {
    print('Failed to fetch banners: ${listResponse.statusCode} - ${listResponse.body}');
  }

  // 2. Define banners to upload
  final banners = [
    {
      'name': 'Back to school offer',
      'path': 'banners/banner_back_to_school.png',
    },
    {
      'name': 'Office essentials offer',
      'path': 'banners/banner_office_essentials.png',
    },
  ];

  // 3. Upload and insert
  for (final banner in banners) {
    final file = File(banner['path']!);
    if (!await file.exists()) {
      print('Error: File ${banner['path']} does not exist. Skipping.');
      continue;
    }

    print('Uploading ${banner['name']} to Cloudinary...');
    final cloudinaryUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
    final uploadRequest = http.MultipartRequest('POST', cloudinaryUrl)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final uploadResponse = await uploadRequest.send();
    if (uploadResponse.statusCode == 200) {
      final responseData = await uploadResponse.stream.bytesToString();
      final json = jsonDecode(responseData);
      final String secureUrl = json['secure_url'];
      print('Uploaded ${banner['name']} successfully! URL: $secureUrl');

      // Insert into Firestore
      print('Inserting ${banner['name']} into Firestore...');
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final payload = {
        'fields': {
          'imageUrl': {'stringValue': secureUrl},
          'isActive': {'booleanValue': true},
          'targetCategoryId': {'nullValue': null},
          'targetProductId': {'nullValue': null},
          'createdAt': {'timestampValue': nowStr},
        }
      };

      final createResponse = await http.post(
        listUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (createResponse.statusCode == 200) {
        print('Inserted banner document for ${banner['name']} successfully!');
      } else {
        print('Failed to insert banner document: ${createResponse.statusCode} - ${createResponse.body}');
      }
    } else {
      print('Failed to upload image ${banner['name']} to Cloudinary: ${uploadResponse.statusCode}');
    }
  }

  print('Banner upload script finished.');
}
