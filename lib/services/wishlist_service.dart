import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class WishlistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ProductModel>> watchWishlist(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addToWishlist(String userId, ProductModel product) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(product.id)
        .set(product.toFirestore());
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .delete();
  }
}
