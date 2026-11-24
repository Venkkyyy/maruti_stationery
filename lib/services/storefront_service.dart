import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/storefront_section_model.dart';
import '../models/storefront_page_model.dart';
import '../models/product_collection_model.dart';
import '../models/campaign_model.dart';
import '../models/product_model.dart';
import 'admin_audit_service.dart';

class StorefrontService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────────────────────────────────────────────────────────────────
  // 1. PUBLISHED PAGE STREAM (Customer & Admin Live View)
  // ───────────────────────────────────────────────────────────────────────────

  Stream<StorefrontPageModel> streamPublishedPage(String pageId) {
    return _db.collection('storefront_pages').doc(pageId).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) {
        // Fallback to legacy settings/home_layout if storefront_pages doc does not exist yet
        return _fetchLegacyHomeLayout(pageId);
      }
      return StorefrontPageModel.fromFirestore(doc);
    });
  }

  Future<StorefrontPageModel> _fetchLegacyHomeLayout(String pageId) async {
    try {
      final legacyDoc = await _db.collection('settings').doc('home_layout').get();
      if (legacyDoc.exists && legacyDoc.data() != null) {
        final rawList = legacyDoc.data()!['sections'] as List<dynamic>?;
        if (rawList != null && rawList.isNotEmpty) {
          final sections = <StorefrontSectionModel>[];
          for (int i = 0; i < rawList.length; i++) {
            final item = rawList[i];
            if (item is Map) {
              sections.add(StorefrontSectionModel.fromMap(item, fallbackOrder: i));
            }
          }
          sections.sort((a, b) => a.order.compareTo(b.order));
          return StorefrontPageModel(
            pageId: pageId,
            pageName: 'Home Storefront',
            sections: sections,
            version: 1,
            publishedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {}

    // Default baseline
    return StorefrontPageModel(
      pageId: pageId,
      pageName: 'Home Storefront',
      sections: StorefrontSectionModel.defaultSections,
      version: 1,
      publishedAt: DateTime.now(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. DRAFT STOREFRONT MANAGEMENT (Admin Working Canvas)
  // ───────────────────────────────────────────────────────────────────────────

  Stream<StorefrontPageModel> streamDraftPage(String pageId) {
    return _db
        .collection('storefront_pages')
        .doc(pageId)
        .collection('drafts')
        .doc('current')
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) {
        // Fallback: seed draft from currently published version
        final published = await streamPublishedPage(pageId).first;
        return published.copyWith(status: 'draft');
      }
      return StorefrontPageModel.fromFirestore(doc);
    });
  }

  Future<void> saveDraft({
    required String pageId,
    required List<StorefrontSectionModel> sections,
    required String userId,
    String? pageName,
  }) async {
    final draftRef = _db
        .collection('storefront_pages')
        .doc(pageId)
        .collection('drafts')
        .doc('current');

    final mappedSections = sections.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key).toMap();
    }).toList();

    await draftRef.set({
      'pageId': pageId,
      'pageName': pageName ?? 'Home Storefront',
      'sections': mappedSections,
      'updatedBy': userId,
      'status': 'draft',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. VALIDATION ENGINE (Ensures safe, non-crashing customer configurations)
  // ───────────────────────────────────────────────────────────────────────────

  List<String> validateSections(List<StorefrontSectionModel> sections) {
    final errors = <String>[];
    final ids = <String>{};

    for (int i = 0; i < sections.length; i++) {
      final s = sections[i];
      if (s.id.trim().isEmpty) {
        errors.add('Section #${i + 1} has an empty ID.');
      } else if (ids.contains(s.id)) {
        errors.add('Duplicate section ID found: "${s.id}".');
      } else {
        ids.add(s.id);
      }

      if (s.title.trim().isEmpty && s.type != StorefrontSectionType.ads) {
        errors.add('Section "${s.id}" (${StorefrontSectionType.getLabel(s.type)}) is missing a title.');
      }

      if (s.validFrom != null && s.validTo != null && s.validTo!.isBefore(s.validFrom!)) {
        errors.add('Section "${s.title}": End date cannot be earlier than start date.');
      }
    }

    return errors;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. ATOMIC PUBLISHING, VERSION SNAPSHOTS & AUDIT LOGS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> publishDraft({
    required String pageId,
    required String userId,
    String? changeSummary,
  }) async {
    // 1. Fetch current draft
    final draftDoc = await _db
        .collection('storefront_pages')
        .doc(pageId)
        .collection('drafts')
        .doc('current')
        .get();

    List<StorefrontSectionModel> sections = StorefrontSectionModel.defaultSections;
    String pageName = 'Home Storefront';

    if (draftDoc.exists && draftDoc.data() != null) {
      final pageModel = StorefrontPageModel.fromFirestore(draftDoc);
      sections = pageModel.sections;
      pageName = pageModel.pageName;
    }

    // 2. Validate
    final validationErrors = validateSections(sections);
    if (validationErrors.isNotEmpty) {
      throw Exception('Publishing validation failed:\n${validationErrors.join('\n')}');
    }

    // 3. Fetch next version number
    final pageDoc = await _db.collection('storefront_pages').doc(pageId).get();
    int currentVersion = 0;
    if (pageDoc.exists && pageDoc.data() != null) {
      currentVersion = (pageDoc.data()!['version'] as num?)?.toInt() ?? 0;
    }
    final nextVersion = currentVersion + 1;
    final now = DateTime.now();

    final mappedSections = sections.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key).toMap();
    }).toList();

    // 4. Save Immutable Historical Version Snapshot
    final versionRef = _db
        .collection('storefront_pages')
        .doc(pageId)
        .collection('versions')
        .doc('v_$nextVersion');

    await versionRef.set({
      'version': nextVersion,
      'pageId': pageId,
      'pageName': pageName,
      'sections': mappedSections,
      'publishedBy': userId,
      'publishedAt': Timestamp.fromDate(now),
      'changeSummary': changeSummary ?? 'Published version $nextVersion',
      'status': 'published',
    });

    // 5. Update Live Storefront Page Document atomically
    await _db.collection('storefront_pages').doc(pageId).set({
      'pageId': pageId,
      'pageName': pageName,
      'version': nextVersion,
      'sections': mappedSections,
      'publishedBy': userId,
      'publishedAt': Timestamp.fromDate(now),
      'changeSummary': changeSummary ?? 'Published version $nextVersion',
      'status': 'published',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 6. Mirror to legacy settings/home_layout for backward compatibility
    if (pageId == 'home') {
      await _db.collection('settings').doc('home_layout').set({
        'sections': mappedSections,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 7. Record in Admin Audit Log
    await AdminAuditService.logAction(
      action: 'Publish Storefront',
      targetType: 'storefront_page',
      targetId: pageId,
      description: 'Published storefront version $nextVersion (${sections.length} active sections). $changeSummary',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. VERSION HISTORY & ROLLBACK
  // ───────────────────────────────────────────────────────────────────────────

  Stream<List<StorefrontPageModel>> streamVersionHistory(String pageId) {
    return _db
        .collection('storefront_pages')
        .doc(pageId)
        .collection('versions')
        .orderBy('version', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StorefrontPageModel.fromFirestore(d)).toList());
  }

  Future<void> rollbackToVersion({
    required String pageId,
    required StorefrontPageModel historicalVersion,
    required String userId,
  }) async {
    // Stage historical sections into draft, then publish as a brand new forward version
    await saveDraft(
      pageId: pageId,
      sections: historicalVersion.sections,
      userId: userId,
      pageName: historicalVersion.pageName,
    );

    await publishDraft(
      pageId: pageId,
      userId: userId,
      changeSummary: 'Rolled back to version ${historicalVersion.version}',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. PRODUCT COLLECTIONS SERVICE
  // ───────────────────────────────────────────────────────────────────────────

  Stream<List<ProductCollectionModel>> streamCollections() {
    return _db
        .collection('product_collections')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return ProductCollectionModel.defaultCollections;
      }
      return snap.docs.map((d) => ProductCollectionModel.fromFirestore(d)).toList();
    });
  }

  Future<void> saveCollection(ProductCollectionModel collection) async {
    final ref = collection.id.isNotEmpty
        ? _db.collection('product_collections').doc(collection.id)
        : _db.collection('product_collections').doc();

    final toSave = collection.copyWith(
      id: ref.id,
      updatedAt: DateTime.now(),
    );

    await ref.set(toSave.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteCollection(String id) async {
    await _db.collection('product_collections').doc(id).delete();
  }

  Future<List<ProductModel>> fetchProductsForCollection({
    required ProductCollectionModel collection,
    required List<ProductModel> allProducts,
  }) async {
    if (collection.type == CollectionType.manual) {
      if (collection.productIds.isEmpty) return [];
      final idSet = collection.productIds.toSet();
      final matched = allProducts.where((p) => idSet.contains(p.id) && p.isActive).toList();
      // Maintain exact ordering specified in collection.productIds
      matched.sort((a, b) {
        final iA = collection.productIds.indexOf(a.id);
        final iB = collection.productIds.indexOf(b.id);
        return iA.compareTo(iB);
      });
      return matched.take(collection.maxProducts).toList();
    } else {
      // Automatic rule evaluation
      final ruleType = collection.rules['ruleType'] ?? CollectionRuleType.trending;
      var filtered = allProducts.where((p) => p.isActive).toList();

      switch (ruleType) {
        case CollectionRuleType.trending:
          filtered.sort((a, b) => b.salesCount.compareTo(a.salesCount));
          break;
        case CollectionRuleType.bestSellers:
          filtered.sort((a, b) => b.salesCount.compareTo(a.salesCount));
          break;
        case CollectionRuleType.newArrivals:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case CollectionRuleType.topRated:
          final minRating = (collection.rules['minRating'] as num?)?.toDouble() ?? 4.0;
          filtered = filtered.where((p) => p.averageRating >= minRating).toList();
          filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
          break;
        case CollectionRuleType.onSale:
          filtered = filtered.where((p) => p.isOnSale).toList();
          break;
        case CollectionRuleType.category:
          final catId = collection.rules['categoryId'] as String?;
          if (catId != null) {
            filtered = filtered.where((p) => p.categoryId == catId).toList();
          }
          break;
      }
      return filtered.take(collection.maxProducts).toList();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. CAMPAIGN MANAGEMENT SERVICE
  // ───────────────────────────────────────────────────────────────────────────

  Stream<List<CampaignModel>> streamCampaigns() {
    return _db
        .collection('campaigns')
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList());
  }

  Future<void> saveCampaign(CampaignModel campaign) async {
    final ref = campaign.id.isNotEmpty
        ? _db.collection('campaigns').doc(campaign.id)
        : _db.collection('campaigns').doc();

    final toSave = campaign.copyWith(
      id: ref.id,
      updatedAt: DateTime.now(),
    );

    await ref.set(toSave.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteCampaign(String id) async {
    await _db.collection('campaigns').doc(id).delete();
  }
}

