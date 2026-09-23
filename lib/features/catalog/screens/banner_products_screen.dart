import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product_model.dart';
import '../../catalog/widgets/product_card.dart';

/// Fetches ALL active products then filters client-side by [tag].
/// This avoids needing a Firestore composite index for array-contains queries.
final _bannerProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, tag) async {
  final snap = await FirebaseFirestore.instance
      .collection('products')
      .where('isActive', isEqualTo: true)
      .get();

  final all = snap.docs.map(ProductModel.fromFirestore).toList();

  // Filter: product tags list contains the banner tag (case-insensitive)
  final tagLower = tag.toLowerCase();
  final filtered = all
      .where((p) => p.tags.any((t) => t.toLowerCase() == tagLower))
      .toList();

  return filtered;
});

class BannerProductsScreen extends ConsumerWidget {
  final String tag;
  final String title;

  const BannerProductsScreen({
    super.key,
    required this.tag,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_bannerProductsProvider(tag));

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 56, color: context.colors.textHint),
                const SizedBox(height: 12),
                Text('Something went wrong',
                    style: TextStyle(
                        fontSize: 16, color: context.colors.textSecondary)),
              ],
            ),
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 72, color: context.colors.border),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re still stocking up this collection.\nCheck back soon!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: context.colors.textHint),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Result count header
              Container(
                width: double.infinity,
                color: context.colors.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  '${products.length} product${products.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      ProductCard(product: products[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
