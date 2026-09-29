import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class AdminProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // IMPORTANT: You must replace these with your actual Cloudinary keys!
  static const String _cloudinaryCloudName = 'eizhyg2w';
  static const String _cloudinaryUploadPreset = 'maruti_preset';

  // 1. ADD Product — uploads images and saves their delete_tokens to Firestore
  Future<void> addProduct(ProductModel product, List<File> imageFiles) async {
    final uploadResults = await uploadImagesWithTokens(imageFiles);
    final imageUrls = uploadResults.map((r) => r['url']!).toList();
    final deleteTokens = uploadResults.map((r) => r['delete_token']!).toList();

    final newProduct = product.copyWith(
      images: imageUrls,
      imageDeleteTokens: deleteTokens,
    );

    await _db.collection('products').doc(newProduct.id).set(newProduct.toFirestore());
  }

  // 2. UPDATE Product (Price, Stock, Discount, etc.)
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('products').doc(productId).update(updates);
  }

  // 3. DELETE Product — also deletes images from Cloudinary using stored delete_tokens
  Future<void> deleteProduct(String productId, List<String> imageUrls, {List<String> deleteTokens = const []}) async {
    // Delete each image from Cloudinary using its delete_token (works with unsigned presets)
    for (final token in deleteTokens) {
      if (token.isNotEmpty) {
        try {
          await _deleteCloudinaryImageByToken(token);
        } catch (e) {
          // Log but don't fail the whole delete if one image removal fails
          debugPrint('Warning: Could not delete Cloudinary image (token=$token): $e');
        }
      }
    }
    // Delete from Firestore
    await _db.collection('products').doc(productId).delete();
  }

  /// Deletes a Cloudinary image using the delete_token returned at upload time.
  /// This works with unsigned upload presets — no API secret needed.
  Future<void> _deleteCloudinaryImageByToken(String deleteToken) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/delete_by_token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': deleteToken}),
    );
    if (response.statusCode != 200) {
      debugPrint('Cloudinary delete_by_token returned ${response.statusCode}: ${response.body}');
    }
  }

  /// Uploads images and returns a list of maps with 'url' and 'delete_token' for each.
  Future<List<Map<String, String>>> uploadImagesWithTokens(List<File> files) async {
    final List<Map<String, String>> results = [];
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');

    for (int i = 0; i < files.length; i++) {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', files[i].path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        results.add({
          'url': json['secure_url'] as String,
          'delete_token': (json['delete_token'] as String?) ?? '',
        });
      } else {
        throw Exception('Failed to upload image to Cloudinary: ${response.statusCode}');
      }
    }
    return results;
  }

  /// Legacy helper — uploads images and returns only URLs (used where tokens aren't needed).
  Future<List<String>> uploadImages(List<File> files) async {
    final results = await uploadImagesWithTokens(files);
    return results.map((r) => r['url']!).toList();
  }

  /// Uploads a single video file to Cloudinary and returns its secure URL.
  Future<String> uploadVideo(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/video/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['secure_url'] as String;
    } else {
      throw Exception('Failed to upload video to Cloudinary: ${response.statusCode}');
    }
  }
}
