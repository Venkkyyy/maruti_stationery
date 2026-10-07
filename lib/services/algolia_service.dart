import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class AlgoliaService {
  static const String appId = '77V8QWTSSU';
  static const String searchKey = '588b757dd7c3bc8fe08d5d481105360b';
  static const String indexName = 'products';

  Future<List<ProductModel>> searchProducts({
    required String query,
    String? categoryId,
    int page = 0,
  }) async {
    // --- REAL ALGOLIA SEARCH (0 FIRESTORE READS) ---
    try {
      // FIX: use string concatenation to avoid escaped $ issues
      final url = Uri.parse(
        'https://' + appId + '-dsn.algolia.net/1/indexes/' + indexName + '/query',
      );

      String params = 'query=' + Uri.encodeComponent(query) +
          '&page=' + page.toString() +
          '&hitsPerPage=20' +
          '&attributesToRetrieve=objectID,name,description,price,mrp,brand,unit,stock,images,tags,isActive,categoryId';

      if (categoryId != null && categoryId.isNotEmpty) {
        params += '&facetFilters=' + Uri.encodeComponent('categoryId:$categoryId');
      }

      final response = await http.post(
        url,
        headers: {
          'X-Algolia-Application-Id': appId,
          'X-Algolia-API-Key': searchKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'params': params}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hits = data['hits'] as List<dynamic>;

        debugPrint('Algolia: returned ${hits.length} results for "$query"');

        return hits.map<ProductModel>((hit) {
          final map = hit as Map<String, dynamic>;
          return ProductModel(
            id: map['objectID'] as String? ?? '',
            categoryId: map['categoryId'] as String? ?? '',
            name: map['name'] as String? ?? '',
            description: map['description'] as String? ?? '',
            price: (map['price'] as num?)?.toInt() ?? 0,
            mrp: (map['mrp'] as num?)?.toInt() ??
                (map['price'] as num?)?.toInt() ?? 0,
            brand: map['brand'] as String? ?? '',
            unit: map['unit'] as String? ?? 'piece',
            stock: (map['stock'] as num?)?.toInt() ?? 0,
            images: List<String>.from(map['images'] as List? ?? []),
            tags: List<String>.from(map['tags'] as List? ?? []),
            isActive: map['isActive'] as bool? ?? true,
            createdAt: DateTime.now(),
          );
        }).toList();
      } else {
        debugPrint('Algolia HTTP ${response.statusCode}: ${response.body}');
        return _localSearchFallback(query: query, categoryId: categoryId);
      }
    } catch (e) {
      debugPrint('Algolia failed, using local fallback: $e');
      return _localSearchFallback(query: query, categoryId: categoryId);
    }
  }

  /// Firestore fallback — used when Algolia is unreachable or index is empty.
  Future<List<ProductModel>> _localSearchFallback({
    required String query,
    String? categoryId,
  }) async {
    final queryLower = query.toLowerCase();
    try {
      var firestoreQuery = FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true);

      if (categoryId != null && categoryId.isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await firestoreQuery
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 10));

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return products.where((p) {
        final nameMatch = p.name.toLowerCase().contains(queryLower);
        final brandMatch = p.brand.toLowerCase().contains(queryLower);
        final tagsMatch =
            p.tags.any((tag) => tag.toLowerCase().contains(queryLower));
        return nameMatch || brandMatch || tagsMatch;
      }).toList();
    } catch (e) {
      debugPrint('Local search fallback also failed: $e');
      return [];
    }
  }
}
