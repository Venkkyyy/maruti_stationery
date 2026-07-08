import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  static const int _pageSize = 20;

  Future<List<ProductModel>> getProductsByCategory({
    required String categoryId,
    DocumentSnapshot? lastDoc,
    String? sortBy,
    int? maxPrice,
    int? minPrice,
  }) async {
    Query query = FirebaseFirestore.instance.collection('products');

    if (categoryId != 'All' && categoryId != 'all') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (sortBy != null) {
      if (sortBy == 'price_low') {
        query = query.orderBy('price', descending: false);
      } else if (sortBy == 'price_high') {
        query = query.orderBy('price', descending: true);
      } else if (sortBy == 'newest') {
        query = query.orderBy('createdAt', descending: true);
      }
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(_pageSize);
    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((p) => p.isActive)
        .toList();
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    
    if (doc.exists) {
      return ProductModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists ? ProductModel.fromFirestore(doc) : null);
  }

  Future<List<ProductModel>> getRelatedProducts({
    required String categoryId,
    required String excludeProductId,
    int limit = 6,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .limit(limit * 2) // fetch a bit more to account for inactive ones
        .get();

    final products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((p) => p.isActive && p.id != excludeProductId)
        .take(limit)
        .toList();

    return products;
  }

  Future<List<ProductModel>> getNewArrivals({int limit = 10}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();
  }
}
