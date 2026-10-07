import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'algolia_service.dart';

class AlgoliaAdminService {
  static const String adminKey = 'f33148bed3d625099bf74c1a728b5774';

  static const _headers = {
    'X-Algolia-Application-Id': AlgoliaService.appId,
    'X-Algolia-API-Key': adminKey,
    'Content-Type': 'application/json',
  };

  /// Syncs a single product to Algolia (called when adding/editing a product).
  Future<void> syncProduct(ProductModel product) async {
    try {
      // FIX: use string concatenation — escaped \$ was creating literal $ in URL
      final url = Uri.parse(
        'https://' + AlgoliaService.appId + '.algolia.net/1/indexes/' +
        AlgoliaService.indexName + '/' + product.id,
      );

      final body = {
        'objectID': product.id,
        'categoryId': product.categoryId,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'mrp': product.mrp,
        'brand': product.brand,
        'unit': product.unit,
        'stock': product.stock,
        'images': product.images,
        'tags': product.tags,
        'isActive': product.isActive,
      };

      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Algolia: synced product ${product.id}');
      } else {
        debugPrint('Algolia Sync Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Algolia Sync Exception: $e');
    }
  }

  /// Bulk syncs ALL products to Algolia (used from Admin Settings).
  Future<int> bulkSyncAllProducts() async {
    // Fetch ALL products (no isActive filter — sync everything)
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .get()
        .timeout(const Duration(seconds: 20));

    final products =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

    debugPrint('Algolia Sync: found ${products.length} products to sync');

    if (products.isEmpty) {
      throw Exception('No products found in Firestore. Add products first.');
    }

    // FIX: use string concatenation to avoid escaped \$ literal dollar signs
    final url = Uri.parse(
      'https://' + AlgoliaService.appId + '.algolia.net/1/indexes/' +
      AlgoliaService.indexName + '/batch',
    );

    final requests = products.map((product) {
      return {
        'action': 'updateObject',
        'body': {
          'objectID': product.id,
          'categoryId': product.categoryId,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'mrp': product.mrp,
          'brand': product.brand,
          'unit': product.unit,
          'stock': product.stock,
          'images': product.images,
          'tags': product.tags,
          'isActive': product.isActive,
        },
      };
    }).toList();

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'requests': requests}),
    ).timeout(const Duration(seconds: 30));

    debugPrint('Algolia batch response: ${response.statusCode} — ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('Algolia: bulk synced ${products.length} products');
      return products.length;
    } else {
      throw Exception(
        'Algolia Error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
