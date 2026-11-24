import 'package:cloud_firestore/cloud_firestore.dart';
import 'storefront_section_model.dart';

class StorefrontPageModel {
  final String pageId; // e.g. 'home', 'category_pens', 'campaign_back_to_school'
  final String pageName;
  final String pageType; // 'home', 'category', 'campaign'
  final List<StorefrontSectionModel> sections;
  final int version;
  final DateTime? publishedAt;
  final String? publishedBy;
  final String? changeSummary;
  final String status; // 'draft', 'published', 'archived'

  const StorefrontPageModel({
    required this.pageId,
    required this.pageName,
    this.pageType = 'home',
    required this.sections,
    this.version = 1,
    this.publishedAt,
    this.publishedBy,
    this.changeSummary,
    this.status = 'published',
  });

  StorefrontPageModel copyWith({
    String? pageId,
    String? pageName,
    String? pageType,
    List<StorefrontSectionModel>? sections,
    int? version,
    DateTime? publishedAt,
    String? publishedBy,
    String? changeSummary,
    String? status,
  }) {
    return StorefrontPageModel(
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      pageType: pageType ?? this.pageType,
      sections: sections ?? this.sections,
      version: version ?? this.version,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      changeSummary: changeSummary ?? this.changeSummary,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pageId': pageId,
      'pageName': pageName,
      'pageType': pageType,
      'sections': sections.asMap().entries.map((e) {
        return e.value.copyWith(order: e.key).toMap();
      }).toList(),
      'version': version,
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'publishedBy': publishedBy,
      'changeSummary': changeSummary,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StorefrontPageModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final rawSections = data['sections'] as List<dynamic>? ?? [];

    final sections = <StorefrontSectionModel>[];
    for (int i = 0; i < rawSections.length; i++) {
      final s = rawSections[i];
      if (s is Map) {
        sections.add(StorefrontSectionModel.fromMap(s, fallbackOrder: i));
      }
    }
    sections.sort((a, b) => a.order.compareTo(b.order));

    return StorefrontPageModel(
      pageId: doc.id,
      pageName: data['pageName'] ?? 'Home Storefront',
      pageType: data['pageType'] ?? 'home',
      sections: sections.isNotEmpty ? sections : StorefrontSectionModel.defaultSections,
      version: (data['version'] as num?)?.toInt() ?? 1,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      publishedBy: data['publishedBy'] as String?,
      changeSummary: data['changeSummary'] as String?,
      status: data['status'] ?? 'published',
    );
  }
}

