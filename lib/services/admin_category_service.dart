import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminCategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static const String _cloudinaryCloudName = 'eizhyg2w';
  static const String _cloudinaryUploadPreset = 'maruti_preset';

  Future<void> addCategory(CategoryModel category, File? imageFile) async {
    String imageUrl = category.image;
    String? deleteToken;
    
    if (imageFile != null) {
      final uploadData = await _uploadCategoryImageWithToken(imageFile);
      imageUrl = uploadData['url']!;
      deleteToken = uploadData['delete_token'];
    }
    
    final newCategory = CategoryModel(
      id: category.id,
      name: category.name,
      image: imageUrl,
      imageDeleteToken: deleteToken,
      parentId: category.parentId,
      order: category.order,
      isActive: category.isActive,
    );
    
    await _db.collection('categories').doc(newCategory.id).set(newCategory.toFirestore());
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> updates) async {
    await _db.collection('categories').doc(categoryId).update(updates);
  }

  Future<void> deleteCategory(String categoryId) async {
    final doc = await _db.collection('categories').doc(categoryId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final token = data['imageDeleteToken'] as String?;
      if (token != null && token.isNotEmpty) {
        try {
          await _deleteCloudinaryImageByToken(token);
        } catch (e) {
          print('Warning: Could not delete Cloudinary image: $e');
        }
      }
    }
    await _db.collection('categories').doc(categoryId).delete();
  }

  Future<void> _deleteCloudinaryImageByToken(String deleteToken) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/delete_by_token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': deleteToken}),
    );
    if (response.statusCode != 200) {
      print('Cloudinary delete_by_token returned ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> uploadCategoryImage(File file) async {
    final uploadData = await _uploadCategoryImageWithToken(file);
    return uploadData['url']!;
  }

  Future<Map<String, String>> _uploadCategoryImageWithToken(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return {
        'url': json['secure_url'],
        'delete_token': json['delete_token']
      };
    } else {
      throw Exception('Failed to upload image to Cloudinary: ${response.statusCode}');
    }
  }
}

