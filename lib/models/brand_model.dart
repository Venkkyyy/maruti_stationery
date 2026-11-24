import 'package:cloud_firestore/cloud_firestore.dart';

class BrandModel {
  final String id;
  final String name;
  final String logoUrl;
  final bool isActive;
  final DateTime createdAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BrandModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final map = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
    return BrandModel(
      id: doc.id,
      name: map['name']?.toString() ?? '',
      logoUrl: map['logoUrl']?.toString() ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
