import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final bool isActive;
  final String? targetCategoryId;
  final String? targetProductId;
  /// Tag used to filter products (e.g. "back_to_school", "office_essentials")
  final String? tag;
  /// Human-readable title shown on the banner product screen
  final String? title;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.isActive = true,
    this.targetCategoryId,
    this.targetProductId,
    this.tag,
    this.title,
    required this.createdAt,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BannerModel(
      id: documentId,
      imageUrl: map['imageUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      targetCategoryId: map['targetCategoryId'] as String?,
      targetProductId: map['targetProductId'] as String?,
      tag: map['tag'] as String?,
      title: map['title'] as String?,
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
      'tag': tag,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
