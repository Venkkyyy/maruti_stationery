import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

part 'product_provider.g.dart';

@riverpod
ProductService productService(Ref ref) {
  return ProductService();
}

@riverpod
Future<ProductModel?> getProduct(Ref ref, String productId) {
  return ref.watch(productServiceProvider).getProduct(productId);
}

@riverpod
Stream<ProductModel?> watchProduct(Ref ref, String productId) {
  return ref.watch(productServiceProvider).watchProduct(productId);
}

@riverpod
Future<List<ProductModel>> getProductsByCategory(Ref ref, String categoryId) {
  return ref.watch(productServiceProvider).getProductsByCategory(categoryId: categoryId);
}

@riverpod
Future<List<ProductModel>> getNewArrivals(Ref ref, {int limit = 10}) {
  return ref.watch(productServiceProvider).getNewArrivals(limit: limit);
}

@riverpod
Future<List<ProductModel>> getRelatedProducts(Ref ref, String categoryId, String excludeProductId) {
  return ref.watch(productServiceProvider).getRelatedProducts(
    categoryId: categoryId,
    excludeProductId: excludeProductId,
  );
}
