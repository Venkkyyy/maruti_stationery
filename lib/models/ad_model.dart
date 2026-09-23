import 'package:cloud_firestore/cloud_firestore.dart';

/// CTA destination type for an ad.
enum AdCtaType { product, category, collection, url, none }

AdCtaType _parseCtaType(String? raw) {
  switch (raw) {
    case 'product':
      return AdCtaType.product;
    case 'category':
      return AdCtaType.category;
    case 'collection':
      return AdCtaType.collection;
    case 'url':
      return AdCtaType.url;
    default:
      return AdCtaType.none;
  }
}

class AdModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final AdCtaType ctaType;
  final String ctaValue;   // product ID / category ID / tag / URL
  final String ctaLabel;   // e.g. "Shop Now"
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int placementFrequency; // show after every N products
  final int sortOrder;          // lower = higher priority / shown first
  final int impressions;
  final int clicks;
  final DateTime createdAt;

  const AdModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.ctaType = AdCtaType.none,
    this.ctaValue = '',
    this.ctaLabel = 'Shop Now',
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.placementFrequency = 8,
    this.sortOrder = 0,
    this.impressions = 0,
    this.clicks = 0,
    required this.createdAt,
  });

  bool get hasCta => ctaType != AdCtaType.none && ctaValue.isNotEmpty;

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      ctaType: _parseCtaType(data['ctaType'] as String?),
      ctaValue: data['ctaValue'] as String? ?? '',
      ctaLabel: data['ctaLabel'] as String? ?? 'Shop Now',
      isActive: data['isActive'] as bool? ?? true,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      placementFrequency: (data['placementFrequency'] as num?)?.toInt() ?? 8,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      impressions: (data['impressions'] as num?)?.toInt() ?? 0,
      clicks: (data['clicks'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'videoUrl': videoUrl,
    'thumbnailUrl': thumbnailUrl,
    'ctaType': ctaType.name,
    'ctaValue': ctaValue,
    'ctaLabel': ctaLabel,
    'isActive': isActive,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'placementFrequency': placementFrequency,
    'sortOrder': sortOrder,
    'impressions': impressions,
    'clicks': clicks,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AdModel copyWith({
    String? videoUrl,
    String? thumbnailUrl,
    AdCtaType? ctaType,
    String? ctaValue,
    String? ctaLabel,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? placementFrequency,
    int? sortOrder,
    int? impressions,
    int? clicks,
  }) {
    return AdModel(
      id: id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      ctaType: ctaType ?? this.ctaType,
      ctaValue: ctaValue ?? this.ctaValue,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      placementFrequency: placementFrequency ?? this.placementFrequency,
      sortOrder: sortOrder ?? this.sortOrder,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      createdAt: createdAt,
    );
  }
}
