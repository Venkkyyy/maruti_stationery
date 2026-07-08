import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/product_provider.dart';
import '../../../models/product_model.dart';
import '../../catalog/widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;

  final List<String> _categories = [
    'All',
    'Pens',
    'Notebooks',
    'Inks',
    'Art Supplies',
    'Accessories',
  ];

  @override
  Widget build(BuildContext context) {
    final productsAsync = _selectedCategory == 0 
        ? ref.watch(getNewArrivalsProvider(limit: 6))
        : ref.watch(getProductsByCategoryProvider(_categories[_selectedCategory].toLowerCase()));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: context.colors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: context.colors.border,
            leading: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: context.colors.textPrimary),
              onPressed: () => context.push('/notifications'),
            ),
            title: Text(
              'Maruti Stationery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.primary,
              ),
            ),
            actions: [
              // Removed cart and search icons as they are now in the bottom nav
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Search Bar ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => context.go('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: context.colors.textHint, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Search catalogs, products...',
                            style: TextStyle(
                              color: context.colors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category Chips ─────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final bool selected = _selectedCategory == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? context.colors.primary
                                : context.colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? context.colors.primary
                                  : context.colors.border,
                            ),
                          ),
                          child: Text(
                            _categories[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : context.colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Hero Banner ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0D1B2A),
                          Color(0xFF1A2D42),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative elements
                        Positioned(
                          right: -10,
                          top: -20,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  context.colors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        // Pen icon decorative
                        Positioned(
                          right: 24,
                          top: 24,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SIGNATURE COLLECTION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Elevate Your Desk\nExperience',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => context.go('/catalog'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: context.colors.primary,
                                    borderRadius:
                                        BorderRadius.circular(24),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Shop Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Product sections
                productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No products available', style: TextStyle(color: context.colors.textHint))),
                      );
                    }
                    
                    // Mock variations for UI sections
                    final trendingProducts = products.reversed.toList();
                    final topRatedProducts = products.toList();
                    final buyAgainProducts = products.length > 2 ? (products.toList()..insert(0, products.last)).sublist(0, products.length) : products.toList();

                    return Column(
                      children: [
                        _buildHorizontalProductSection('New Arrivals', products, showViewMore: true),
                        _buildHorizontalProductSection('Trending', trendingProducts),
                        _buildHorizontalProductSection('Top Rating', topRatedProducts),
                        _buildHorizontalProductSection('Buy Again', buyAgainProducts),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductSection(String title, List<ProductModel> products, {bool showViewMore = false}) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (showViewMore)
                GestureDetector(
                  onTap: () => context.go('/catalog'),
                  child: Row(
                    children: [
                      Text('View more', style: AppTextStyles.sectionLink),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: context.colors.primary, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return SizedBox(
                width: 160,
                child: ProductCard(product: products[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}








