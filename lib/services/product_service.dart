import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  static const int _pageSize = 20;

  // Mock Products
  final List<ProductModel> _mockProducts = [
    ProductModel(
      id: 'mock-1',
      name: 'Premium Leather Notebook',
      description: 'A beautiful leather-bound notebook for your daily journaling.',
      price: 150000,
      mrp: 180000,
      categoryId: 'notebooks',
      brand: 'Maruti',
      images: ['https://via.placeholder.com/400'],
      stock: 50,
      unit: 'piece',
      tags: ['premium', 'notebook', 'leather'],
      isActive: true,
      createdAt: DateTime.now(),
    ),
    ProductModel(
      id: 'mock-2',
      name: 'Executive Fountain Pen',
      description: 'Smooth writing experience with a gold-plated nib.',
      price: 250000,
      mrp: 300000,
      categoryId: 'pens',
      brand: 'Parker',
      images: ['https://via.placeholder.com/400'],
      stock: 30,
      unit: 'piece',
      tags: ['premium', 'pen', 'fountain'],
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  Future<List<ProductModel>> getProductsByCategory({
    required String categoryId,
    DocumentSnapshot? lastDoc,
    String? sortBy,
    int? maxPrice,
    int? minPrice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockProducts;
  }

  Future<ProductModel?> getProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockProducts.first;
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return Stream.value(_mockProducts.first);
  }

  Future<List<ProductModel>> getRelatedProducts({
    required String categoryId,
    required String excludeProductId,
    int limit = 6,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockProducts;
  }

  Future<List<ProductModel>> getNewArrivals({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockProducts;
  }
}
