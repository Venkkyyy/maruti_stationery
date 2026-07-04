import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class WishlistService {
  final List<ProductModel> _mockWishlist = [];

  Stream<List<ProductModel>> watchWishlist(String userId) {
    return Stream.value(_mockWishlist);
  }

  Future<void> addToWishlist(String userId, ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_mockWishlist.any((p) => p.id == product.id)) {
      _mockWishlist.add(product);
    }
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockWishlist.removeWhere((p) => p.id == productId);
  }
}
