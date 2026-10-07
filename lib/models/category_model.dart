import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String? imageDeleteToken;
  final String? parentId;
  final int order;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.imageDeleteToken,
    this.parentId,
    required this.order,
    required this.isActive,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      imageDeleteToken: data['imageDeleteToken'],
      parentId: data['parentId'],
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
      'imageDeleteToken': imageDeleteToken,
      'parentId': parentId,
      'order': order,
      'isActive': isActive,
    };
  }
}
