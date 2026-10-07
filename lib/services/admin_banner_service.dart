import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/banner_model.dart';

class AdminBannerService {
  static const String _cloudinaryCloudName = 'eizhyg2w';
  static const String _cloudinaryUploadPreset = 'maruti_preset';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBanner({
    XFile? imageFile,
    String? directImageUrl,
    required bool isActive,
    String? targetCategoryId,
    String? targetProductId,
    String? tag,
    String? title,
  }) async {
    String imageUrl = directImageUrl?.trim() ?? '';
    String? deleteToken;
    if (imageFile != null) {
      final uploadData = await _uploadImageToCloudinaryWithToken(imageFile);
      imageUrl = uploadData['url']!;
      deleteToken = uploadData['delete_token'];
    }
    
    if (imageUrl.isEmpty) {
      throw Exception('Please select an image or provide an image URL');
    }

    final newBanner = BannerModel(
      id: '',
      imageUrl: imageUrl,
      imageDeleteToken: deleteToken,
      isActive: isActive,
      targetCategoryId: targetCategoryId,
      targetProductId: targetProductId,
      tag: tag,
      title: title,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('banners').add(newBanner.toMap());
  }

  Future<void> updateBanner(
    String id, {
    XFile? newImageFile,
    String? newImageUrl,
    String? existingImageUrl,
    required bool isActive,
    String? targetCategoryId,
    String? targetProductId,
    String? tag,
    String? title,
  }) async {
    String imageUrl = (newImageUrl != null && newImageUrl.trim().isNotEmpty)
        ? newImageUrl.trim()
        : (existingImageUrl ?? '');
    String? deleteToken;
    
    if (newImageFile != null) {
      final uploadData = await _uploadImageToCloudinaryWithToken(newImageFile);
      imageUrl = uploadData['url']!;
      deleteToken = uploadData['delete_token'];
    }

    final updates = <String, dynamic>{
      'imageUrl': imageUrl,
      'isActive': isActive,
      'targetCategoryId': targetCategoryId,
      'targetProductId': targetProductId,
    };
    if (deleteToken != null) {
      updates['imageDeleteToken'] = deleteToken;
    }
    if (tag != null) updates['tag'] = tag;
    if (title != null) updates['title'] = title;

    await _firestore.collection('banners').doc(id).update(updates);
  }

  Future<void> deleteBanner(String id) async {
    final doc = await _firestore.collection('banners').doc(id).get();
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
    await _firestore.collection('banners').doc(id).delete();
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

  Future<void> toggleBannerStatus(String id, bool isActive) async {
    await _firestore.collection('banners').doc(id).update({'isActive': isActive});
  }



  Future<Map<String, String>> _uploadImageToCloudinaryWithToken(XFile file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset;

    try {
      if (!kIsWeb && file.path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
      }
    } catch (_) {
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final json = jsonDecode(responseData);
      return {
        'url': json['secure_url'] as String,
        'delete_token': (json['delete_token'] as String?) ?? '',
      };
    } else {
      throw Exception('Failed to upload image (${response.statusCode}): $responseData');
    }
  }
}
