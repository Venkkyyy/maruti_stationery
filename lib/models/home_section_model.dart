class HomeSectionModel {
  final String id;
  final String type; // 'categories', 'banners', 'use_case', 'trending', 'new_arrivals', 'buy_again', 'ads', 'custom_products'
  final String title;
  final String subtitle;
  final bool isEnabled;
  final String displayStyle; // 'grid', 'horizontal'
  final String? categoryId;
  final String? categoryName;
  final int limit;
  final int order;

  const HomeSectionModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.isEnabled = true,
    this.displayStyle = 'grid',
    this.categoryId,
    this.categoryName,
    this.limit = 8,
    required this.order,
  });

  HomeSectionModel copyWith({
    String? id,
    String? type,
    String? title,
    String? subtitle,
    bool? isEnabled,
    String? displayStyle,
    String? categoryId,
    String? categoryName,
    int? limit,
    int? order,
  }) {
    return HomeSectionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isEnabled: isEnabled ?? this.isEnabled,
      displayStyle: displayStyle ?? this.displayStyle,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      limit: limit ?? this.limit,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'isEnabled': isEnabled,
      'displayStyle': displayStyle,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'limit': limit,
      'order': order,
    };
  }

  factory HomeSectionModel.fromMap(Map<dynamic, dynamic> map, {int fallbackOrder = 0}) {
    return HomeSectionModel(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? 'custom_products').toString(),
      title: (map['title'] ?? 'Section').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      isEnabled: map['isEnabled'] == true || map['isEnabled'] == null,
      displayStyle: (map['displayStyle'] ?? 'grid').toString(),
      categoryId: map['categoryId']?.toString(),
      categoryName: map['categoryName']?.toString(),
      limit: (map['limit'] as num?)?.toInt() ?? 8,
      order: (map['order'] as num?)?.toInt() ?? fallbackOrder,
    );
  }

  static List<HomeSectionModel> get defaultSections => [
    const HomeSectionModel(
      id: 'sec_categories',
      type: 'categories',
      title: 'Categories',
      subtitle: 'Browse all stationery departments',
      isEnabled: true,
      order: 0,
    ),
    const HomeSectionModel(
      id: 'sec_banners',
      type: 'banners',
      title: 'Promotional Banners',
      subtitle: 'Featured store offers & deals',
      isEnabled: true,
      order: 1,
    ),
    const HomeSectionModel(
      id: 'sec_use_case',
      type: 'use_case',
      title: 'Shop by Essentials',
      subtitle: 'Pens & Notebook essentials',
      isEnabled: true,
      order: 2,
    ),
    const HomeSectionModel(
      id: 'sec_trending',
      type: 'trending',
      title: 'Trending Now',
      subtitle: 'Top selling stationery items',
      isEnabled: true,
      displayStyle: 'grid',
      limit: 10,
      order: 3,
    ),
    const HomeSectionModel(
      id: 'sec_new_arrivals',
      type: 'new_arrivals',
      title: 'Newly Added',
      subtitle: 'Fresh arrivals in store',
      isEnabled: true,
      displayStyle: 'horizontal',
      limit: 8,
      order: 4,
    ),
    const HomeSectionModel(
      id: 'sec_buy_again',
      type: 'buy_again',
      title: 'Buy Again',
      subtitle: 'Items from your past orders',
      isEnabled: true,
      order: 5,
    ),
    const HomeSectionModel(
      id: 'sec_ads',
      type: 'ads',
      title: 'Sponsored Video Ads',
      subtitle: 'Interactive video reels & promos',
      isEnabled: true,
      order: 6,
    ),
  ];
}

