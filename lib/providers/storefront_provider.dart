import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/storefront_page_model.dart';
import '../models/storefront_section_model.dart';
import '../models/product_collection_model.dart';
import '../models/campaign_model.dart';
import '../services/storefront_service.dart';

final storefrontServiceProvider = Provider<StorefrontService>((ref) {
  return StorefrontService();
});

/// Published Storefront Stream with Automatic Offline Cache
final publishedStorefrontStreamProvider =
    StreamProvider.family<StorefrontPageModel, String>((ref, pageId) async* {
  final service = ref.watch(storefrontServiceProvider);
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'cached_storefront_$pageId';

  // 1. Emit cached configuration immediately if available
  final cachedJson = prefs.getString(cacheKey);
  if (cachedJson != null) {
    try {
      final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
      final rawSections = decoded['sections'] as List<dynamic>? ?? [];
      final sections = rawSections
          .map((s) => StorefrontSectionModel.fromMap(s as Map))
          .toList();
      yield StorefrontPageModel(
        pageId: pageId,
        pageName: decoded['pageName'] ?? 'Home Storefront',
        sections: sections.isNotEmpty ? sections : StorefrontSectionModel.defaultSections,
        version: (decoded['version'] as num?)?.toInt() ?? 1,
      );
    } catch (_) {}
  }

  // 2. Stream live updates from Firestore and update cache
  await for (final page in service.streamPublishedPage(pageId)) {
    try {
      final cacheMap = {
        'pageId': page.pageId,
        'pageName': page.pageName,
        'version': page.version,
        'sections': page.sections.map((s) => s.toMap()).toList(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheMap));
    } catch (_) {}
    yield page;
  }
});

/// Draft Storefront Stream (Used by Admin Home Screen Builder and Live Preview)
final draftStorefrontStreamProvider =
    StreamProvider.family<StorefrontPageModel, String>((ref, pageId) {
  final service = ref.watch(storefrontServiceProvider);
  return service.streamDraftPage(pageId);
});

/// Version History Stream
final storefrontVersionHistoryProvider =
    StreamProvider.family<List<StorefrontPageModel>, String>((ref, pageId) {
  final service = ref.watch(storefrontServiceProvider);
  return service.streamVersionHistory(pageId);
});

/// Product Collections Stream
final productCollectionsStreamProvider =
    StreamProvider<List<ProductCollectionModel>>((ref) {
  final service = ref.watch(storefrontServiceProvider);
  return service.streamCollections();
});

/// Active Campaigns Stream
final activeCampaignsStreamProvider =
    StreamProvider<List<CampaignModel>>((ref) {
  final service = ref.watch(storefrontServiceProvider);
  return service.streamCampaigns();
});

