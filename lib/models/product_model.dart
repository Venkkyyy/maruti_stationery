import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final int price;      // ALWAYS store in paise (₹10 = 1000 paise)
  final int mrp;
  final String categoryId;
  final String? subCategoryId;
  final String brand;
  final List<String> images;
  final int stock;
  final String unit;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.mrp,
    required this.categoryId,
    this.subCategoryId,
    required this.brand,
    required this.images,
    required this.stock,
    required this.unit,
    required this.tags,
    required this.isActive,
    required this.createdAt,
  });

  // Price helpers — convert paise to rupees for display only
  double get priceInRupees => price / 100;
  double get mrpInRupees => mrp / 100;
  int get discountPercent => mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;
  bool get isInStock => stock > 0;
  bool get isOnSale => mrp > price;
  String get primaryImage => images.isNotEmpty ? images.first : '';

  // Used for admin editing
  ProductModel copyWith({
    String? name,
    String? description,
    int? price,
    int? mrp,
    int? stock,
    List<String>? images,
    bool? isActive,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      brand: brand,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      unit: unit,
      tags: tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num).toInt(),
      mrp: (data['mrp'] as num).toInt(),
      categoryId: data['categoryId'] ?? '',
      subCategoryId: data['subCategoryId'],
      brand: data['brand'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      stock: (data['stock'] as num).toInt(),
      unit: data['unit'] ?? 'piece',
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'price': price,
    'mrp': mrp,
    'categoryId': categoryId,
    'subCategoryId': subCategoryId,
    'brand': brand,
    'images': images,
    'stock': stock,
    'unit': unit,
    'tags': tags,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
