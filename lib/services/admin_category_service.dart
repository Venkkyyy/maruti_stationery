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
    
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }
    
    final newCategory = CategoryModel(
      id: category.id,
      name: category.name,
      image: imageUrl,
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
    await _db.collection('categories').doc(categoryId).delete();
  }

  Future<String> _uploadImage(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['secure_url'];
    } else {
      throw Exception('Failed to upload image to Cloudinary: ${response.statusCode}');
    }
  }
}
