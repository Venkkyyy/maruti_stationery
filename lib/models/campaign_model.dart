import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignStatus {
  CampaignStatus._();
  static const String draft = 'draft';
  static const String scheduled = 'scheduled';
  static const String active = 'active';
  static const String ended = 'ended';
}

class CampaignModel {
  final String id;
  final String name;
  final String description;
  final String bannerUrl;
  final String? badgeText;
  final String? targetCollectionId;
  final String? targetCategoryId;
  final String? destination;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CampaignModel({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerUrl,
    this.badgeText,
    this.targetCollectionId,
    this.targetCategoryId,
    this.destination,
    required this.startAt,
    required this.endAt,
    this.status = CampaignStatus.active,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCurrentlyLive {
    if (!isEnabled) return false;
    final now = DateTime.now();
    return now.isAfter(startAt) && now.isBefore(endAt);
  }

  CampaignModel copyWith({
    String? id,
    String? name,
    String? description,
    String? bannerUrl,
    String? badgeText,
    String? targetCollectionId,
    String? targetCategoryId,
    String? destination,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      badgeText: badgeText ?? this.badgeText,
      targetCollectionId: targetCollectionId ?? this.targetCollectionId,
      targetCategoryId: targetCategoryId ?? this.targetCategoryId,
      destination: destination ?? this.destination,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'bannerUrl': bannerUrl,
      'badgeText': badgeText,
      'targetCollectionId': targetCollectionId,
      'targetCategoryId': targetCategoryId,
      'destination': destination,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status,
      'isEnabled': isEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CampaignModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      badgeText: data['badgeText'] as String?,
      targetCollectionId: data['targetCollectionId'] as String?,
      targetCategoryId: data['targetCategoryId'] as String?,
      destination: data['destination'] as String?,
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      status: data['status'] ?? CampaignStatus.active,
      isEnabled: data['isEnabled'] == true || data['isEnabled'] == null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

