import 'package:cloud_firestore/cloud_firestore.dart';

/// Predefined Section Types supported by the Server-Driven UI Engine
class StorefrontSectionType {
  StorefrontSectionType._();

  // ── Promotional Sections ──────────────────────────────────────────────────
  static const String heroBanner          = 'hero_banner';
  static const String bannerCarousel      = 'banners'; // matches legacy 'banners'
  static const String promoImageBanner    = 'promo_image_banner';
  static const String offerStrip          = 'offer_strip';
  static const String announcementBar     = 'announcement_bar';
  static const String campaignBanner      = 'campaign_banner';

  // ── Product Sections ──────────────────────────────────────────────────────
  static const String productCarousel     = 'product_carousel';
  static const String productGrid         = 'product_grid';
  static const String trending            = 'trending'; // matches legacy 'trending'
  static const String bestSellers         = 'best_sellers';
  static const String newArrivals         = 'new_arrivals'; // matches legacy
  static const String featuredProducts    = 'featured_products';
  static const String topRated            = 'top_rated';
  static const String recentlyViewed      = 'recently_viewed';
  static const String recommended         = 'recommended';
  static const String frequentlyBought    = 'frequently_bought';
  static const String buyAgain            = 'buy_again'; // matches legacy
  static const String customProducts      = 'custom_products'; // matches legacy

  // ── Category Sections ─────────────────────────────────────────────────────
  static const String categories          = 'categories'; // matches legacy 'categories'
  static const String categoryGrid        = 'category_grid';
  static const String categoryCarousel    = 'category_carousel';
  static const String featuredCategories  = 'featured_categories';
  static const String useCase             = 'use_case'; // matches legacy 'use_case'

  // ── Content & Ads ─────────────────────────────────────────────────────────
  static const String brandCollection     = 'brand_collection';
  static const String promotionalCollection = 'promotional_collection';
  static const String imageText           = 'image_text';
  static const String editorial           = 'editorial';
  static const String ads                 = 'ads'; // matches legacy 'ads'

  static const List<String> allTypes = [
    heroBanner,
    bannerCarousel,
    promoImageBanner,
    offerStrip,
    announcementBar,
    campaignBanner,
    productCarousel,
    productGrid,
    trending,
    bestSellers,
    newArrivals,
    featuredProducts,
    topRated,
    recentlyViewed,
    recommended,
    frequentlyBought,
    buyAgain,
    customProducts,
    categories,
    categoryGrid,
    categoryCarousel,
    featuredCategories,
    useCase,
    brandCollection,
    promotionalCollection,
    imageText,
    editorial,
    ads,
  ];

  static String getLabel(String type) {
    switch (type) {
      case heroBanner: return 'Hero Banner';
      case bannerCarousel: return 'Banner Carousel';
      case promoImageBanner: return 'Promotional Banner Image';
      case offerStrip: return 'Offer Strip';
      case announcementBar: return 'Announcement Bar';
      case campaignBanner: return 'Campaign Banner';
      case productCarousel: return 'Product Carousel';
      case productGrid: return 'Product Grid';
      case trending: return 'Trending Products';
      case bestSellers: return '🔥 Best Sellers';
      case newArrivals: return 'New Arrivals';
      case featuredProducts: return 'Featured Products';
      case topRated: return 'Top Rated Products';
      case recentlyViewed: return 'Recently Viewed';
      case recommended: return 'Recommended for You';
      case frequentlyBought: return 'Frequently Bought Together';
      case buyAgain: return 'Buy Again';
      case customProducts: return 'Curated Product Collection';
      case categories: return 'Category Pills';
      case categoryGrid: return 'Category Grid';
      case categoryCarousel: return 'Category Carousel';
      case featuredCategories: return 'Featured Categories';
      case useCase: return 'Shop by Use Case';
      case brandCollection: return 'Brand Collection';
      case promotionalCollection: return 'Promotional Collection';
      case imageText: return 'Image & Text Feature';
      case editorial: return 'Editorial Stationery Guide';
      case ads: return 'Sponsored Ads';
      default: return type.replaceAll('_', ' ').toUpperCase();
    }
  }
}

/// Dynamic Layout Variants supported by each section type
class StorefrontLayoutVariant {
  StorefrontLayoutVariant._();

  // Products
  static const String carouselStandard  = 'carousel_standard';
  static const String carouselCompact   = 'carousel_compact';
  static const String carouselLarge     = 'carousel_large';
  static const String carouselEditorial = 'carousel_editorial';
  static const String grid2Col          = 'grid_2col';
  static const String grid3Col          = 'grid_3col';
  static const String gridCompact       = 'grid_compact';

  // Categories
  static const String categoryPills     = 'category_pills';
  static const String categoryCards     = 'category_cards';
  static const String categoryGrid2x4   = 'category_grid_2x4';
  static const String categoryCircles   = 'category_circles';

  // Banners
  static const String bannerFull        = 'banner_full';
  static const String bannerSplit       = 'banner_split';
  static const String bannerCarousel    = 'banner_carousel';
  static const String bannerCard        = 'banner_card';
}

/// Server-Driven UI Section Model
class StorefrontSectionModel {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String description;
  final bool isEnabled;
  final int order;
  final String layoutVariant;
  final String dataSource; // 'collection', 'category', 'query', 'manual', 'banners', 'ads'
  final String? collectionId;
  final String? categoryId;
  final String? categoryName;
  final String? campaignId;
  final List<String> manualProductIds;
  final int limit;
  final String? backgroundColor; // hex e.g. '#FAF7EE'
  final String? textColor;
  final double paddingTop;
  final double paddingBottom;
  final String? seeAllDestination;
  final DateTime? validFrom;
  final DateTime? validTo;

  const StorefrontSectionModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.isEnabled = true,
    required this.order,
    this.layoutVariant = StorefrontLayoutVariant.carouselStandard,
    this.dataSource = 'query',
    this.collectionId,
    this.categoryId,
    this.categoryName,
    this.campaignId,
    this.manualProductIds = const [],
    this.limit = 8,
    this.backgroundColor,
    this.textColor,
    this.paddingTop = 0.0,
    this.paddingBottom = 24.0,
    this.seeAllDestination,
    this.validFrom,
    this.validTo,
  });

  bool get isCurrentlyScheduledActive {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return true;
  }

  StorefrontSectionModel copyWith({
    String? id,
    String? type,
    String? title,
    String? subtitle,
    String? description,
    bool? isEnabled,
    int? order,
    String? layoutVariant,
    String? dataSource,
    String? collectionId,
    String? categoryId,
    String? categoryName,
    String? campaignId,
    List<String>? manualProductIds,
    int? limit,
    String? backgroundColor,
    String? textColor,
    double? paddingTop,
    double? paddingBottom,
    String? seeAllDestination,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    return StorefrontSectionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
      layoutVariant: layoutVariant ?? this.layoutVariant,
      dataSource: dataSource ?? this.dataSource,
      collectionId: collectionId ?? this.collectionId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      campaignId: campaignId ?? this.campaignId,
      manualProductIds: manualProductIds ?? this.manualProductIds,
      limit: limit ?? this.limit,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      seeAllDestination: seeAllDestination ?? this.seeAllDestination,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'isEnabled': isEnabled,
      'order': order,
      'layoutVariant': layoutVariant,
      'dataSource': dataSource,
      'collectionId': collectionId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'campaignId': campaignId,
      'manualProductIds': manualProductIds,
      'limit': limit,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'paddingTop': paddingTop,
      'paddingBottom': paddingBottom,
      'seeAllDestination': seeAllDestination,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
    };
  }

  factory StorefrontSectionModel.fromMap(Map<dynamic, dynamic> map, {int fallbackOrder = 0}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    // Convert displayStyle from legacy HomeSectionModel if present
    String variant = (map['layoutVariant'] ?? '').toString();
    if (variant.isEmpty) {
      final style = (map['displayStyle'] ?? '').toString();
      if (style == 'grid') {
        variant = StorefrontLayoutVariant.grid2Col;
      } else if (style == 'horizontal') {
        variant = StorefrontLayoutVariant.carouselStandard;
      } else {
        variant = StorefrontLayoutVariant.carouselStandard;
      }
    }

    return StorefrontSectionModel(
      id: (map['id'] ?? 'sec_${DateTime.now().millisecondsSinceEpoch}').toString(),
      type: (map['type'] ?? StorefrontSectionType.customProducts).toString(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      isEnabled: map['isEnabled'] == true || map['isEnabled'] == null,
      order: (map['order'] as num?)?.toInt() ?? fallbackOrder,
      layoutVariant: variant,
      dataSource: (map['dataSource'] ?? 'query').toString(),
      collectionId: map['collectionId']?.toString(),
      categoryId: map['categoryId']?.toString(),
      categoryName: map['categoryName']?.toString(),
      campaignId: map['campaignId']?.toString(),
      manualProductIds: (map['manualProductIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      limit: (map['limit'] as num?)?.toInt() ?? 8,
      backgroundColor: map['backgroundColor']?.toString(),
      textColor: map['textColor']?.toString(),
      paddingTop: (map['paddingTop'] as num?)?.toDouble() ?? 0.0,
      paddingBottom: (map['paddingBottom'] as num?)?.toDouble() ?? 24.0,
      seeAllDestination: map['seeAllDestination']?.toString(),
      validFrom: parseDate(map['validFrom']),
      validTo: parseDate(map['validTo']),
    );
  }

  /// Default baseline sections for Maruti Stationery storefront
  static List<StorefrontSectionModel> get defaultSections => const [
    StorefrontSectionModel(
      id: 'sec_categories',
      type: StorefrontSectionType.categories,
      title: 'Categories',
      subtitle: 'Browse all stationery departments',
      isEnabled: true,
      order: 0,
      layoutVariant: StorefrontLayoutVariant.categoryPills,
    ),
    StorefrontSectionModel(
      id: 'sec_banners',
      type: StorefrontSectionType.bannerCarousel,
      title: 'Promotional Banners',
      subtitle: 'Featured store offers & deals',
      isEnabled: true,
      order: 1,
      layoutVariant: StorefrontLayoutVariant.bannerCarousel,
    ),
    StorefrontSectionModel(
      id: 'sec_use_case',
      type: StorefrontSectionType.useCase,
      title: 'Shop by Use Case',
      subtitle: 'Essential supplies curated by purpose',
      isEnabled: true,
      order: 2,
      layoutVariant: StorefrontLayoutVariant.categoryCards,
    ),
    StorefrontSectionModel(
      id: 'sec_best_sellers',
      type: StorefrontSectionType.bestSellers,
      title: '🔥 Best Sellers',
      subtitle: 'Top selling stationery items',
      isEnabled: true,
      order: 3,
      layoutVariant: StorefrontLayoutVariant.carouselStandard,
      limit: 10,
    ),
    StorefrontSectionModel(
      id: 'sec_new_arrivals',
      type: StorefrontSectionType.newArrivals,
      title: 'Newly Added',
      subtitle: 'Fresh stock & latest arrivals',
      isEnabled: true,
      order: 4,
      layoutVariant: StorefrontLayoutVariant.carouselStandard,
      limit: 10,
    ),
    StorefrontSectionModel(
      id: 'sec_buy_again',
      type: StorefrontSectionType.buyAgain,
      title: 'Buy Again',
      subtitle: 'Items from your previous orders',
      isEnabled: true,
      order: 5,
      layoutVariant: StorefrontLayoutVariant.carouselStandard,
      limit: 6,
    ),
    StorefrontSectionModel(
      id: 'sec_ads',
      type: StorefrontSectionType.ads,
      title: 'Featured Specials',
      subtitle: 'Sponsored stationery deals',
      isEnabled: true,
      order: 6,
      layoutVariant: StorefrontLayoutVariant.bannerFull,
    ),
  ];
}

