import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/product_model.dart';
import '../models/bulk_import_batch_model.dart';
import 'algolia_admin_service.dart' as maruti_algolia;

class ZipImageFile {
  final String name;
  final Uint8List bytes;
  final String fullPath;

  ZipImageFile({
    required this.name,
    required this.bytes,
    required this.fullPath,
  });
}

class ZipProductMatch {
  final String folderName;
  final String? categoryHint;
  final String? subcategoryHint;
  ProductModel? matchedProduct;
  final List<ZipImageFile> images;
  final bool isMatched;
  final double confidence;

  ZipProductMatch({
    required this.folderName,
    this.categoryHint,
    this.subcategoryHint,
    this.matchedProduct,
    required this.images,
    required this.isMatched,
    this.confidence = 1.0,
  });
}

class ZipMatchResult {
  final List<ZipProductMatch> matches;
  final List<ZipProductMatch> unmatched;
  final int totalImagesCount;
  final int totalFoldersCount;

  ZipMatchResult({
    required this.matches,
    required this.unmatched,
    required this.totalImagesCount,
    required this.totalFoldersCount,
  });

  int get matchedProductsCount => matches.length;
  int get unmatchedProductsCount => unmatched.length;
}

class AdminZipImageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _cloudinaryCloudName = 'eizhyg2w';
  static const String _cloudinaryUploadPreset = 'maruti_preset';

  String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Parses a ZIP file in-memory and pairs its folders to existing Firestore products.
  Future<ZipMatchResult> parseZipArchive(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final Map<String, List<ZipImageFile>> folderImages = {};
    final Map<String, String> folderCategoryHint = {};
    final Map<String, String> folderSubcategoryHint = {};

    int totalImages = 0;

    for (final file in archive) {
      if (!file.isFile) continue;

      final cleanPath = file.name.replaceAll(r'\', '/');
      final lowerPath = cleanPath.toLowerCase();

      // Skip macOS system junk & hidden files
      if (lowerPath.contains('__macosx') ||
          lowerPath.contains('.ds_store') ||
          lowerPath.contains('thumbs.db') ||
          cleanPath.split('/').any((p) => p.startsWith('.'))) {
        continue;
      }

      // Valid image extensions
      if (!lowerPath.endsWith('.jpg') &&
          !lowerPath.endsWith('.jpeg') &&
          !lowerPath.endsWith('.png') &&
          !lowerPath.endsWith('.webp')) {
        continue;
      }

      final parts = cleanPath.split('/').where((s) => s.trim().isNotEmpty).toList();
      if (parts.length < 2) continue;

      final fileName = parts.last;
      final productFolder = parts[parts.length - 2].trim();

      if (parts.length >= 3) {
        folderCategoryHint[productFolder] = parts[0].trim();
      }
      if (parts.length >= 4) {
        folderSubcategoryHint[productFolder] = parts[1].trim();
      }

      final bytes = Uint8List.fromList(file.content as List<int>);
      final imgFile = ZipImageFile(
        name: fileName,
        bytes: bytes,
        fullPath: cleanPath,
      );

      folderImages.putIfAbsent(productFolder, () => []).add(imgFile);
      totalImages++;
    }

    // Sort images inside each folder naturally: 1.jpg, 2.jpg, 3.jpg, 4.jpg
    folderImages.forEach((_, list) {
      list.sort((a, b) {
        final numA = _extractLeadingNumber(a.name);
        final numB = _extractLeadingNumber(b.name);
        if (numA != null && numB != null) {
          return numA.compareTo(numB);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    });

    // Fetch all products from Firestore to find matches
    final productsSnap = await _db.collection('products').get();
    final allProducts = productsSnap.docs.map((d) => ProductModel.fromFirestore(d)).toList();

    final List<ZipProductMatch> matched = [];
    final List<ZipProductMatch> unmatched = [];

    final Set<String> matchedProductIds = {};

    folderImages.forEach((folderName, images) {
      final normFolder = _normalize(folderName);

      ProductModel? bestProduct;
      double bestConfidence = 0.0;

      for (final p in allProducts) {
        if (matchedProductIds.contains(p.id)) continue;

        final normProduct = _normalize(p.name);

        // 1. Exact match
        if (normProduct == normFolder || p.name.trim().toLowerCase() == folderName.toLowerCase()) {
          bestProduct = p;
          bestConfidence = 1.0;
          break;
        }

        // 2. High substring match
        if (normProduct.contains(normFolder) || normFolder.contains(normProduct)) {
          final longer = normProduct.length > normFolder.length ? normProduct.length : normFolder.length;
          final shorter = normProduct.length > normFolder.length ? normFolder.length : normProduct.length;
          final score = shorter / longer;
          if (score > 0.6 && score > bestConfidence) {
            bestProduct = p;
            bestConfidence = score;
          }
        }
      }

      if (bestProduct != null && bestConfidence >= 0.6) {
        matchedProductIds.add(bestProduct.id);
        matched.add(ZipProductMatch(
          folderName: folderName,
          categoryHint: folderCategoryHint[folderName],
          subcategoryHint: folderSubcategoryHint[folderName],
          matchedProduct: bestProduct,
          images: images,
          isMatched: true,
          confidence: bestConfidence,
        ));
      } else {
        unmatched.add(ZipProductMatch(
          folderName: folderName,
          categoryHint: folderCategoryHint[folderName],
          subcategoryHint: folderSubcategoryHint[folderName],
          matchedProduct: null,
          images: images,
          isMatched: false,
          confidence: 0.0,
        ));
      }
    });

    return ZipMatchResult(
      matches: matched,
      unmatched: unmatched,
      totalImagesCount: totalImages,
      totalFoldersCount: folderImages.length,
    );
  }

  int? _extractLeadingNumber(String name) {
    final match = RegExp(r'^(\d+)').firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    final lower = name.toLowerCase();
    if (lower.startsWith('front') || lower.startsWith('main') || lower.startsWith('cover')) return 0;
    if (lower.startsWith('back')) return 99;
    return null;
  }

  /// Uploads matched ZIP images to Cloudinary, updates Firestore `/products/{id}`,
  /// records a rollback batch in `/bulk_import_batches`, and syncs to Algolia.
  Future<BulkImportBatchModel> uploadZipImages({
    required String fileName,
    required String? adminEmail,
    required List<ZipProductMatch> matches,
    required bool replaceExisting,
    void Function(int productIndex, int totalProducts, int photoIndex, int totalPhotos)? onProgress,
  }) async {
    final batchId = const Uuid().v4();
    final int totalPhotos = matches.fold(0, (sum, m) => sum + m.images.length);
    int uploadedPhotos = 0;
    int updatedProducts = 0;

    final List<String> allUploadedDeleteTokens = [];
    final Map<String, dynamic> updatedProductSnapshots = {};
    final List<String> affectedProductIds = [];

    for (int pIdx = 0; pIdx < matches.length; pIdx++) {
      final match = matches[pIdx];
      final product = match.matchedProduct;
      if (product == null) continue;

      // Save previous snapshot of product's images for rollback
      updatedProductSnapshots[product.id] = {
        'images': product.images,
        'imageDeleteTokens': product.imageDeleteTokens,
      };
      affectedProductIds.add(product.id);

      final List<String> newUrls = [];
      final List<String> newDeleteTokens = [];

      for (int i = 0; i < match.images.length; i++) {
        final img = match.images[i];
        try {
          final res = await _uploadImageBytes(img.bytes, img.name);
          newUrls.add(res['url']!);
          if (res['delete_token']!.isNotEmpty) {
            newDeleteTokens.add(res['delete_token']!);
            allUploadedDeleteTokens.add(res['delete_token']!);
          }
        } catch (e) {
          debugPrint('Error uploading image ${img.name} for ${product.name}: $e');
        }

        uploadedPhotos++;
        if (onProgress != null) {
          onProgress(pIdx + 1, matches.length, uploadedPhotos, totalPhotos);
        }
      }

      if (newUrls.isEmpty) continue;

      List<String> finalUrls = [];
      List<String> finalTokens = [];

      if (replaceExisting) {
        finalUrls = newUrls;
        finalTokens = newDeleteTokens;
      } else {
        finalUrls = [...product.images, ...newUrls];
        finalTokens = [...product.imageDeleteTokens, ...newDeleteTokens];
      }

      // Update Firestore product
      await _db.collection('products').doc(product.id).update({
        'images': finalUrls,
        'imageDeleteTokens': finalTokens,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Sync to Algolia
      try {
        final updatedModel = product.copyWith(
          images: finalUrls,
          imageDeleteTokens: finalTokens,
        );
        await maruti_algolia.AlgoliaAdminService().syncProduct(updatedModel);
      } catch (e) {
        debugPrint('Algolia sync failed for ${product.name}: $e');
      }

      updatedProducts++;
    }

    // Save Photo Batch Record in Firestore for Rollback History
    final batchRecord = BulkImportBatchModel(
      id: batchId,
      type: 'zip_photos',
      fileName: fileName,
      timestamp: DateTime.now(),
      adminEmail: adminEmail,
      totalCount: updatedProducts,
      uploadedPhotosCount: allUploadedDeleteTokens.length,
      createdProductIds: affectedProductIds,
      uploadedDeleteTokens: allUploadedDeleteTokens,
      updatedProductSnapshots: updatedProductSnapshots,
      isRolledBack: false,
    );

    await _db.collection('bulk_import_batches').doc(batchId).set(batchRecord.toMap());

    return batchRecord;
  }

  /// Rolls back a ZIP photo upload batch:
  /// - Destroys all uploaded images from Cloudinary using delete tokens
  /// - Restores previous images and delete tokens for each product in Firestore and Algolia
  /// - Marks batch as rolled back
  Future<void> rollbackZipBatch(String batchId) async {
    final doc = await _db.collection('bulk_import_batches').doc(batchId).get();
    if (!doc.exists) {
      throw Exception('Photo batch record not found ($batchId)');
    }

    final batch = BulkImportBatchModel.fromFirestore(doc);
    if (batch.isRolledBack) {
      throw Exception('This photo batch has already been rolled back on ${batch.rolledBackAt}');
    }

    // 1. Delete all newly uploaded photos from Cloudinary cloud using delete tokens
    for (final token in batch.uploadedDeleteTokens) {
      if (token.isNotEmpty) {
        try {
          await _deleteCloudinaryImageByToken(token);
        } catch (e) {
          debugPrint('Warning: Cloudinary photo delete failed: $e');
        }
      }
    }

    // 2. Restore previous product image states in Firestore and Algolia
    for (final entry in batch.updatedProductSnapshots.entries) {
      final pid = entry.key;
      if (pid.trim().isEmpty) continue;

      try {
        if (entry.value is! Map) continue;
        final prevData = Map<String, dynamic>.from(entry.value as Map);

        final prevImages = (prevData['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final prevTokens = (prevData['imageDeleteTokens'] as List?)?.map((e) => e.toString()).toList() ?? [];

        await _db.collection('products').doc(pid).update({
          'images': prevImages,
          'imageDeleteTokens': prevTokens,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final pDoc = await _db.collection('products').doc(pid).get();
        if (pDoc.exists) {
          final restoredProduct = ProductModel.fromFirestore(pDoc);
          await maruti_algolia.AlgoliaAdminService().syncProduct(restoredProduct);
        }
      } catch (e) {
        debugPrint('Error restoring product images for $pid: $e');
      }
    }

    // 3. Mark batch as rolled back
    await _db.collection('bulk_import_batches').doc(batchId).set({
      'isRolledBack': true,
      'rolledBackAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, String>> _uploadImageBytes(Uint8List bytes, String filename) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return {
        'url': json['secure_url'] as String,
        'delete_token': (json['delete_token'] as String?) ?? '',
      };
    } else {
      throw Exception('Cloudinary upload failed: ${response.statusCode}');
    }
  }

  Future<void> _deleteCloudinaryImageByToken(String deleteToken) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/delete_by_token');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': deleteToken}),
    );
  }
}
