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

  // 1. ADD Product
  Future<void> addProduct(ProductModel product, List<File> imageFiles) async {
    // First, upload images to Cloudinary
    List<String> imageUrls = await uploadImages(imageFiles);
    
    // Create new product with image URLs
    final newProduct = product.copyWith(images: imageUrls);
    
    await _db.collection('products').doc(newProduct.id).set(newProduct.toFirestore());
  }

  // 2. UPDATE Product (Price, Stock, Discount, etc.)
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('products').doc(productId).update(updates);
  }

  // 3. DELETE Product
  Future<void> deleteProduct(String productId, List<String> imageUrls) async {
    // With unsigned uploads, you cannot securely delete images directly from the app.
    // They will remain on Cloudinary (you have 25,000 GBs of free storage, so it is negligible).
    // If you ever need to bulk delete orphaned photos, you can do it from the Cloudinary dashboard.
    
    // Delete from Firestore
    await _db.collection('products').doc(productId).delete();
  }

  // Helper to upload images to Cloudinary using their REST API
  Future<List<String>> uploadImages(List<File> files) async {


    List<String> urls = [];
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');

    for (int i = 0; i < files.length; i++) {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', files[i].path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        urls.add(json['secure_url']); // Cloudinary returns the CDN URL!
      } else {
        throw Exception('Failed to upload image to Cloudinary: ${response.statusCode}');
      }
    }
    return urls;
  }
}
