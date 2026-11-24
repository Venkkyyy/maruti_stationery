import 'package:cloud_firestore/cloud_firestore.dart';

class BulkImportBatchModel {
  final String id;
  final String type; // 'excel_products' | 'zip_photos'
  final String fileName;
  final DateTime timestamp;
  final String? adminEmail;
  final int totalCount;
  final int newProductsCount;
  final int replacedProductsCount;
  final int uploadedPhotosCount;
  final List<String> createdProductIds;
  final List<String> uploadedDeleteTokens; // All delete tokens from Cloudinary to destroy on rollback
  final Map<String, dynamic> updatedProductSnapshots; // productId -> previous Map
  final List<String> createdCategoryIds;
  final List<String> createdBrandIds;
  final bool isRolledBack;
  final DateTime? rolledBackAt;

  BulkImportBatchModel({
    required this.id,
    this.type = 'excel_products',
    required this.fileName,
    required this.timestamp,
    this.adminEmail,
    required this.totalCount,
    this.newProductsCount = 0,
    this.replacedProductsCount = 0,
    this.uploadedPhotosCount = 0,
    required this.createdProductIds,
    this.uploadedDeleteTokens = const [],
    this.updatedProductSnapshots = const {},
    this.createdCategoryIds = const [],
    this.createdBrandIds = const [],
    this.isRolledBack = false,
    this.rolledBackAt,
  });

  bool get isPhotoBatch => type == 'zip_photos';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'fileName': fileName,
      'timestamp': Timestamp.fromDate(timestamp),
      'adminEmail': adminEmail,
      'totalCount': totalCount,
      'newProductsCount': newProductsCount,
      'replacedProductsCount': replacedProductsCount,
      'uploadedPhotosCount': uploadedPhotosCount,
      'createdProductIds': createdProductIds,
      'uploadedDeleteTokens': uploadedDeleteTokens,
      'updatedProductSnapshots': updatedProductSnapshots,
      'createdCategoryIds': createdCategoryIds,
      'createdBrandIds': createdBrandIds,
      'isRolledBack': isRolledBack,
      'rolledBackAt': rolledBackAt != null ? Timestamp.fromDate(rolledBackAt!) : null,
    };
  }

  factory BulkImportBatchModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

    Map<String, dynamic> snapshots = {};
    if (data['updatedProductSnapshots'] is Map) {
      (data['updatedProductSnapshots'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          snapshots[k.toString()] = v is Map ? Map<String, dynamic>.from(v) : v;
        }
      });
    }

    return BulkImportBatchModel(
      id: doc.id,
      type: data['type']?.toString() ?? 'excel_products',
      fileName: data['fileName']?.toString() ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      adminEmail: data['adminEmail']?.toString(),
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      newProductsCount: (data['newProductsCount'] as num?)?.toInt() ?? 0,
      replacedProductsCount: (data['replacedProductsCount'] as num?)?.toInt() ?? 0,
      uploadedPhotosCount: (data['uploadedPhotosCount'] as num?)?.toInt() ?? 0,
      createdProductIds: (data['createdProductIds'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      uploadedDeleteTokens: (data['uploadedDeleteTokens'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      updatedProductSnapshots: snapshots,
      createdCategoryIds: (data['createdCategoryIds'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      createdBrandIds: (data['createdBrandIds'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      isRolledBack: data['isRolledBack'] == true,
      rolledBackAt: (data['rolledBackAt'] is Timestamp)
          ? (data['rolledBackAt'] as Timestamp).toDate()
          : null,
    );
  }
}
