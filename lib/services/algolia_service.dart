import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class AlgoliaService {
  // These are PUBLIC keys — safe in Flutter app
  static const String appId = 'YOUR_ALGOLIA_APP_ID';
  static const String searchKey = 'YOUR_ALGOLIA_SEARCH_KEY'; // search-only key

  Future<List<ProductModel>> searchProducts({
    required String query,
    String? categoryId,
    int page = 0,
  }) async {
    final queryLower = query.toLowerCase();
    
    // For a real production app with thousands of products, Algolia is necessary.
    // Since it's stubbed out, we will fallback to a local in-memory search 
    // over active products to ensure the search UI functions for the prototype.
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
        
    final products = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    
    return products.where((p) {
      final nameMatch = p.name.toLowerCase().contains(queryLower);
      final tagsMatch = p.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      final catMatch = categoryId == null || p.categoryId == categoryId;
      
      return (nameMatch || tagsMatch) && catMatch;
    }).toList();
  }
}
