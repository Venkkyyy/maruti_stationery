import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/brand_model.dart';
import '../core/errors/app_exception.dart';

class AdminBrandService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream all brands
  Stream<List<BrandModel>> watchBrands() {
    return _db
        .collection('brands')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BrandModel.fromFirestore(doc)).toList());
  }

  // Add brand
  Future<void> addBrand(BrandModel brand) async {
    try {
      await _db.collection('brands').doc(brand.id).set(brand.toMap());
    } catch (e) {
      throw AppException('Failed to add brand: $e');
    }
  }

  // Update brand
  Future<void> updateBrand(BrandModel brand) async {
    try {
      await _db.collection('brands').doc(brand.id).update(brand.toMap());
    } catch (e) {
      throw AppException('Failed to update brand: $e');
    }
  }

  // Delete brand
  Future<void> deleteBrand(String brandId) async {
    try {
      await _db.collection('brands').doc(brandId).delete();
    } catch (e) {
      throw AppException('Failed to delete brand: $e');
    }
  }

  Future<String> uploadBrandImage(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/eizhyg2w/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'maruti_preset'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['secure_url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
