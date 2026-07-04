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
    // In production, instantiate search client and query index 'products'.
    // Stubbed out to allow clean compilation and testing without real credentials.
    return [];
  }
}
