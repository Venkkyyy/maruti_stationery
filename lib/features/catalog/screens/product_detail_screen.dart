import 'dart:ui';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../models/product_model.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImage = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _qty = 1;
  Map<String, String> _selectedVariations = {};

  void _addToBag(ProductModel product) async {
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(product, _qty, selectedVariations: _selectedVariations);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to Cart!'),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _buyNow(ProductModel product) async {
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(product, _qty, selectedVariations: _selectedVariations);
      if (mounted) {
        context.push('/checkout/address');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(watchProductProvider(widget.productId));

    return productAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colors.background,
        body: Center(child: Text('Error: ')),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            backgroundColor: context.colors.background,
            body: const Center(child: Text('Product not found.')),
          );
        }

        final wishlistAsync = ref.watch(watchWishlistProvider);
        final isWishlisted =
            wishlistAsync.value?.any((p) => p.id == product.id) ?? false;

        // Ensure default variations are selected
        if (_selectedVariations.isEmpty && product.variations.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                product.variations.forEach((k, v) {
                  if (v.isNotEmpty) _selectedVariations[k] = v.first;
                });
              });
            }
          });
        }

        final cartAsync = ref.watch(cartProvider);
        // Check if exact same variation combination is in cart
        final isInCart =
            cartAsync.value?.any((item) {
              if (item.productId != product.id) return false;
              if (product.variations.isEmpty) return true;
              for (final key in _selectedVariations.keys) {
                if (item.selectedVariations[key] != _selectedVariations[key])
                  return false;
              }
              return true;
            }) ??
            false;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEFF6FF),
                  Color(0xFFFFF1F2),
                  Color(0xFFF0FDF4),
                  Color(0xFFF8FAFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Image Header
                      SliverAppBar(
                        expandedHeight: 420,
                        pinned: true,
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                        elevation: 0,
                        leading: _buildCircularIcon(
                          Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                        ),
                        actions: [
                          _buildCircularIcon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            iconColor: isWishlisted
                                ? context.colors.error
                                : context.colors.textPrimary,
                            onTap: () {
                              if (isWishlisted) {
                                ref
                                    .read(wishlistProvider.notifier)
                                    .remove(product.id);
                              } else {
                                ref
                                    .read(wishlistProvider.notifier)
                                    .add(product);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            children: [
                              Container(
                                color: context.colors.surfaceGrey,
                                width: double.infinity,
                                height: 420,
                                child: product.images.isNotEmpty
                                    ? CarouselSlider(
                                        carouselController: _carouselController,
                                        options: CarouselOptions(
                                          height: 420,
                                          viewportFraction: 1.0,
                                          enableInfiniteScroll: false,
                                          onPageChanged: (index, reason) {
                                            setState(
                                              () => _selectedImage = index,
                                            );
                                          },
                                        ),
                                        items: product.images.map((img) {
                                          return CachedNetworkImage(
                                            imageUrl: img,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 600,
                                          );
                                        }).toList(),
                                      )
                                    : Icon(
                                        Icons.image,
                                        size: 100,
                                        color: context.colors.border,
                                      ),
                              ),
                              // Indicators
                              if (product.images.length > 1)
                                Positioned(
                                  bottom: 20,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      product.images.length,
                                      (i) {
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width: _selectedImage == i ? 16 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _selectedImage == i
                                                ? context.colors.primary
                                                : Colors.grey.withValues(
                                                    alpha: 0.5,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Details Section
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Specifications row
                              if (product.specifications.isNotEmpty) ...[
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...product.specifications.entries.map((
                                        e,
                                      ) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.colors.surfaceGrey,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.key,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      context.colors.textHint,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                e.value,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: context
                                                      .colors
                                                      .textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      // View details button
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.colors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: context.colors.primary
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'View\ndetails',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Rating & Delivery time
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: context.colors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '11 mins',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '|',
                                    style: TextStyle(
                                      color: context.colors.border,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      return ref
                                          .watch(
                                            productReviewsProvider(product.id),
                                          )
                                          .when(
                                            data: (reviews) {
                                              if (reviews.isEmpty) {
                                                return GestureDetector(
                                                  onTap: () => context.push(
                                                    '/catalog/product/${product.id}/reviews',
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .star_outline_rounded,
                                                        color: context
                                                            .colors
                                                            .textHint,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '0.0 (0)',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: context
                                                              .colors
                                                              .textHint,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              double avg =
                                                  reviews
                                                      .map((r) => r.rating)
                                                      .reduce((a, b) => a + b) /
                                                  reviews.length;
                                              return GestureDetector(
                                                onTap: () => context.push(
                                                  '/catalog/product/${product.id}/reviews',
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star_rounded,
                                                      color:
                                                          Colors.amber.shade600,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      avg.toStringAsFixed(1),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .amber
                                                            .shade700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '(${reviews.length})',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: context
                                                            .colors
                                                            .textHint,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            loading: () => const SizedBox(
                                              height: 12,
                                              width: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            error: (_, __) => const SizedBox(),
                                          );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Name
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Stock tag
                              Row(
                                children: [
                                  Text(
                                    product.unit == 'piece'
                                        ? '1 pc'
                                        : '1 ${product.unit}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  if (product.stock > 0 &&
                                      product.stock <= 5) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            size: 12,
                                            color: Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${product.stock} left',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Price Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatPrice(product.price),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  if (product.isOnSale) ...[
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'MRP ${AppFormatters.formatPrice(product.mrp)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.colors.textHint,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Brand Tile
                              FutureBuilder<DocumentSnapshot?>(
                                future: product.brandId != null
                                    ? FirebaseFirestore.instance
                                          .collection('brands')
                                          .doc(product.brandId)
                                          .get()
                                    : Future.value(null),
                                builder: (context, snapshot) {
                                  String? logoUrl;
                                  if (snapshot.hasData &&
                                      snapshot.data != null &&
                                      snapshot.data!.exists) {
                                    final data =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
                                    logoUrl = data['logoUrl'] as String?;
                                  }
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceGrey
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        if (logoUrl != null &&
                                            logoUrl.isNotEmpty)
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              image: DecorationImage(
                                                image: NetworkImage(logoUrl),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: context.colors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: context.colors.border
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                product.brand.isNotEmpty
                                                    ? product.brand[0]
                                                          .toUpperCase()
                                                    : 'M',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: context
                                                      .colors
                                                      .textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.brand.isNotEmpty
                                                    ? product.brand
                                                    : 'Maruti',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: context
                                                      .colors
                                                      .textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Explore all products',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context
                                                      .colors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: context.colors.textHint,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Policy Tile
                              if (product.isReturnable ||
                                  product.returnPolicy != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceGrey
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.published_with_changes_rounded,
                                        color: context.colors.textPrimary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          product.returnPolicy ??
                                              '72 hours only replacement',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: context.colors.textHint,
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),

                              if (product.variations.isNotEmpty) ...[
                                ...product.variations.entries
                                    .where((e) => e.value.isNotEmpty)
                                    .map((entry) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: entry.value.map((val) {
                                              final isSelected =
                                                  _selectedVariations[entry
                                                      .key] ==
                                                  val;
                                              return ChoiceChip(
                                                label: Text(val),
                                                selected: isSelected,
                                                onSelected: (selected) {
                                                  if (selected) {
                                                    setState(
                                                      () =>
                                                          _selectedVariations[entry
                                                                  .key] =
                                                              val,
                                                    );
                                                  }
                                                },
                                                selectedColor:
                                                    context.colors.primary,
                                                labelStyle: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : context
                                                            .colors
                                                            .textPrimary,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      );
                                    }),
                                Divider(
                                  color: context.colors.border.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Description
                              Text(
                                product.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.colors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 32),

                              if (product.highlights.isNotEmpty) ...[
                                Text(
                                  'Highlights',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...product.highlights.map(
                                  (highlight) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: context.colors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            highlight,
                                            style: TextStyle(
                                              color:
                                                  context.colors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),

                              const SizedBox(height: 16),

                              // View Reviews Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/catalog/product/${product.id}/reviews',
                                  ),
                                  icon: Icon(
                                    Icons.rate_review_outlined,
                                    color: context.colors.primary,
                                  ),
                                  label: Text(
                                    'View Reviews',
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: context.colors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Suggested Products Section
                              _buildSuggestedProducts(product),

                              const SizedBox(height: 24),

                              // Top Products Section
                              _buildTopProducts(product),

                              const SizedBox(
                                height: 100,
                              ), // padding for bottom bar
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed Bottom Bar with Add to Cart and Buy Now
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Price and Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.unit == 'piece'
                                    ? '1 pc'
                                    : '1 ${product.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatPrice(product.price),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  if (product.isOnSale) ...[
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        'MRP ${AppFormatters.formatPrice(product.mrp)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.textHint,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Inclusive of all taxes',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add to cart Button (like screenshot)
                        SizedBox(
                          width: 140,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: product.isInStock
                                ? () {
                                    if (isInCart) {
                                      context.push('/cart');
                                    } else {
                                      _addToBag(product);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: product.isInStock
                                  ? context.colors.primary
                                  : context.colors.surfaceGrey,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              product.isInStock
                                  ? (isInCart ? 'Go to cart' : 'Add to cart')
                                  : 'Out of Stock',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularIcon(
    IconData icon, {
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildFeatureIcon(BuildContext context, IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProducts(ProductModel currentProduct) {
    final relatedAsync = ref.watch(
      getRelatedProductsProvider(currentProduct.categoryId, currentProduct.id),
    );
    return relatedAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: 155,
                    child: ProductCard(product: products[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopProducts(ProductModel currentProduct) {
    final topAsync = ref.watch(getNewArrivalsProvider(limit: 10));
    return topAsync.when(
      data: (products) {
        final filtered = products
            .where((p) => p.id != currentProduct.id)
            .toList();
        if (filtered.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: 155,
                    child: ProductCard(product: filtered[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
