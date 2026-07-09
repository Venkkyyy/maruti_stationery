import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/banner_model.dart';

class AdminBannerService {
  static const String _cloudinaryCloudName = 'eizhyg2w';
  static const String _cloudinaryUploadPreset = 'maruti_preset';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBanner(XFile imageFile, bool isActive, {String? targetCategoryId, String? targetProductId}) async {
    final imageUrl = await _uploadImageToCloudinary(imageFile);
    
    final newBanner = BannerModel(
      id: '',
      imageUrl: imageUrl,
      isActive: isActive,
      targetCategoryId: targetCategoryId,
      targetProductId: targetProductId,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('banners').add(newBanner.toMap());
  }

  Future<void> updateBanner(String id, XFile? newImageFile, String? existingImageUrl, bool isActive, {String? targetCategoryId, String? targetProductId}) async {
    String imageUrl = existingImageUrl ?? '';
    
    if (newImageFile != null) {
      imageUrl = await _uploadImageToCloudinary(newImageFile);
    }

    await _firestore.collection('banners').doc(id).update({
      'imageUrl': imageUrl,
      'isActive': isActive,
      'targetCategoryId': targetCategoryId,
      'targetProductId': targetProductId,
    });
  }

  Future<void> deleteBanner(String id) async {
    await _firestore.collection('banners').doc(id).delete();
  }

  Future<void> toggleBannerStatus(String id, bool isActive) async {
    await _firestore.collection('banners').doc(id).update({'isActive': isActive});
  }

  Future<String> _uploadImageToCloudinary(XFile file) async {
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
