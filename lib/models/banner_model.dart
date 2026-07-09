import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final bool isActive;
  final String? targetCategoryId;
  final String? targetProductId;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.isActive = true,
    this.targetCategoryId,
    this.targetProductId,
    required this.createdAt,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BannerModel(
      id: documentId,
      imageUrl: map['imageUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      targetCategoryId: map['targetCategoryId'] as String?,
      targetProductId: map['targetProductId'] as String?,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'isActive': isActive,
      'targetCategoryId': targetCategoryId,
      'targetProductId': targetProductId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
