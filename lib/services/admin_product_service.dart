import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class AdminProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. ADD Product
  Future<void> addProduct(ProductModel product, List<File> imageFiles) async {
    // First, upload images to Storage
    List<String> imageUrls = await _uploadImages(product.id, imageFiles);
    
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
    // Delete images from Storage first to save space
    for (String url in imageUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (e) {
        // Log error but continue deleting document
        debugPrint('Failed to delete image: $e'); 
      }
    }
    
    // Delete from Firestore
    await _db.collection('products').doc(productId).delete();
  }

  // Helper to upload images
  Future<List<String>> _uploadImages(String productId, List<File> files) async {
    List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      final ref = _storage.ref().child('products/$productId/image_$i.jpg');
      final uploadTask = await ref.putFile(files[i]);
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }
}
