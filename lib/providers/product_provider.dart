import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

part 'product_provider.g.dart';

@riverpod
ProductService productService(Ref ref) {
  return ProductService();
}

/// Real-time stream of active products by category (or all products if categoryId is 'all').
/// Updates instantly in real-time when admin creates, edits, deletes, or toggles active state.
final activeProductsStreamProvider = StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
  Query query = FirebaseFirestore.instance
      .collection('products')
      .where('isActive', isEqualTo: true);

  if (categoryId.toLowerCase() != 'all' && categoryId.isNotEmpty) {
    query = query.where('categoryId', isEqualTo: categoryId);
  }

  return query.limit(50).snapshots().map((snapshot) {
    final products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((p) => p.isActive)
        .toList();
    return products;
  });
});

@riverpod
Future<ProductModel?> getProduct(Ref ref, String productId) {
  return ref.watch(productServiceProvider).getProduct(productId);
}

@riverpod
Stream<ProductModel?> watchProduct(Ref ref, String productId) {
  return ref.watch(productServiceProvider).watchProduct(productId);
}

@riverpod
Future<List<ProductModel>> getProductsByCategory(Ref ref, String categoryId) async {
  // Watches the real-time stream so UI updates immediately when products change
  return ref.watch(activeProductsStreamProvider(categoryId).future);
}

@riverpod
Future<List<ProductModel>> getNewArrivals(Ref ref, {int limit = 10}) async {
  // Watches the real-time stream so UI updates immediately when products change
  final all = await ref.watch(activeProductsStreamProvider('all').future);
  return all.take(limit).toList();
}

@riverpod
Future<List<ProductModel>> getRelatedProducts(Ref ref, String categoryId, String excludeProductId) async {
  final snap = await FirebaseFirestore.instance
      .collection('products')
      .where('categoryId', isEqualTo: categoryId)
      .where('isActive', isEqualTo: true)
      .limit(10)
      .get();

  return snap.docs
      .map((doc) => ProductModel.fromFirestore(doc))
      .where((p) => p.isActive && p.id != excludeProductId)
      .toList();
}
