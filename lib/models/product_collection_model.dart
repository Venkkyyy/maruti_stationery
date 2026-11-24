import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionType {
  CollectionType._();
  static const String manual = 'manual';
  static const String automatic = 'automatic';
}

class CollectionRuleType {
  CollectionRuleType._();
  static const String trending = 'trending';
  static const String bestSellers = 'best_sellers';
  static const String newArrivals = 'new_arrivals';
  static const String topRated = 'top_rated';
  static const String onSale = 'on_sale';
  static const String category = 'category';
  static const String brand = 'brand';
}

class ProductCollectionModel {
  final String id;
  final String name;
  final String description;
  final String type; // 'manual' or 'automatic'
  final List<String> productIds; // for manual collections
  final Map<String, dynamic> rules; // for automatic collections
  final int sortOrder;
  final int maxProducts;
  final String? imageUrl;
  final String? destination;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductCollectionModel({
    required this.id,
    required this.name,
    required this.description,
    this.type = CollectionType.manual,
    this.productIds = const [],
    this.rules = const {},
    this.sortOrder = 0,
    this.maxProducts = 20,
    this.imageUrl,
    this.destination,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductCollectionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    List<String>? productIds,
    Map<String, dynamic>? rules,
    int? sortOrder,
    int? maxProducts,
    String? imageUrl,
    String? destination,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      productIds: productIds ?? this.productIds,
      rules: rules ?? this.rules,
      sortOrder: sortOrder ?? this.sortOrder,
      maxProducts: maxProducts ?? this.maxProducts,
      imageUrl: imageUrl ?? this.imageUrl,
      destination: destination ?? this.destination,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'productIds': productIds,
      'rules': rules,
      'sortOrder': sortOrder,
      'maxProducts': maxProducts,
      'imageUrl': imageUrl,
      'destination': destination,
      'isEnabled': isEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductCollectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ProductCollectionModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? CollectionType.manual,
      productIds: (data['productIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rules: (data['rules'] as Map<String, dynamic>?) ?? const {},
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      maxProducts: (data['maxProducts'] as num?)?.toInt() ?? 20,
      imageUrl: data['imageUrl'] as String?,
      destination: data['destination'] as String?,
      isEnabled: data['isEnabled'] == true || data['isEnabled'] == null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// System default pre-configured collections
  static List<ProductCollectionModel> get defaultCollections => [
    ProductCollectionModel(
      id: 'col_trending',
      name: 'Trending Today',
      description: 'Popular stationery picks with high activity',
      type: CollectionType.automatic,
      rules: {'ruleType': CollectionRuleType.trending},
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductCollectionModel(
      id: 'col_best_sellers',
      name: 'Best Sellers',
      description: 'Most loved stationery items in store',
      type: CollectionType.automatic,
      rules: {'ruleType': CollectionRuleType.bestSellers},
      sortOrder: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductCollectionModel(
      id: 'col_new_arrivals',
      name: 'New Arrivals',
      description: 'Freshly stocked supplies and notebooks',
      type: CollectionType.automatic,
      rules: {'ruleType': CollectionRuleType.newArrivals},
      sortOrder: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductCollectionModel(
      id: 'col_top_rated',
      name: 'Top Rated Essentials',
      description: 'Items rated 4.5+ stars by verified customers',
      type: CollectionType.automatic,
      rules: {'ruleType': CollectionRuleType.topRated, 'minRating': 4.0},
      sortOrder: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductCollectionModel(
      id: 'col_clearance',
      name: 'Mega Clearance Offers',
      description: 'Special discounts and clearance deals',
      type: CollectionType.automatic,
      rules: {'ruleType': CollectionRuleType.onSale},
      sortOrder: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}

