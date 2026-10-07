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
  final String? brandId;
  final bool isBestSeller;
  final List<String> images;
  final List<String> imageDeleteTokens; // Cloudinary delete tokens for each image
  final int stock;
  final String unit;
  final List<String> tags;
  final bool isActive;
  final bool isReturnable;
  final String? returnPolicy;
  final Map<String, List<String>> variations;
  final Map<String, String> specifications;
  final List<String> highlights;
  final DateTime createdAt;
  final int salesCount;
  final double averageRating;
  final int reviewCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.mrp,
    required this.categoryId,
    this.subCategoryId,
    required this.brand,
    this.brandId,
    this.isBestSeller = false,
    required this.images,
    this.imageDeleteTokens = const [],
    required this.stock,
    required this.unit,
    required this.tags,
    required this.isActive,
    this.isReturnable = false,
    this.returnPolicy,
    this.variations = const {},
    this.specifications = const {},
    this.highlights = const [],
    required this.createdAt,
    this.salesCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
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
    List<String>? imageDeleteTokens,
    bool? isActive,
    bool? isReturnable,
    String? returnPolicy,
    Map<String, List<String>>? variations,
    Map<String, String>? specifications,
    List<String>? highlights,
    String? brandId,
    bool? isBestSeller,
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
      brandId: brandId ?? this.brandId,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      images: images ?? this.images,
      imageDeleteTokens: imageDeleteTokens ?? this.imageDeleteTokens,
      stock: stock ?? this.stock,
      unit: unit,
      tags: tags,
      isActive: isActive ?? this.isActive,
      isReturnable: isReturnable ?? this.isReturnable,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      variations: variations ?? this.variations,
      specifications: specifications ?? this.specifications,
      highlights: highlights ?? this.highlights,
      createdAt: createdAt,
      salesCount: salesCount,
      averageRating: averageRating,
      reviewCount: reviewCount,
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
      brandId: data['brandId'],
      isBestSeller: data['isBestSeller'] ?? false,
      images: List<String>.from(data['images'] ?? []),
      imageDeleteTokens: List<String>.from(data['imageDeleteTokens'] ?? []),
      stock: (data['stock'] as num).toInt(),
      unit: data['unit'] ?? 'piece',
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? true,
      isReturnable: data['isReturnable'] ?? false,
      returnPolicy: data['returnPolicy'],
      variations: data['variations'] != null
          ? Map<String, List<String>>.from(
              (data['variations'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, List<String>.from(v)),
              ),
            )
          : {},
      specifications: data['specifications'] != null
          ? Map<String, String>.from(data['specifications'] as Map<dynamic, dynamic>)
          : {},
      highlights: List<String>.from(data['highlights'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      salesCount: (data['salesCount'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
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
    'brandId': brandId,
    'isBestSeller': isBestSeller,
    'images': images,
    'imageDeleteTokens': imageDeleteTokens,
    'stock': stock,
    'unit': unit,
    'tags': tags,
    'isActive': isActive,
    'isReturnable': isReturnable,
    'returnPolicy': returnPolicy,
    'variations': variations,
    'specifications': specifications,
    'highlights': highlights,
    'createdAt': Timestamp.fromDate(createdAt),
    'salesCount': salesCount,
    'averageRating': averageRating,
    'reviewCount': reviewCount,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
