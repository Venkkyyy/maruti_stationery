import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  static const String shopPhone = '+919876543210';

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _selectedImage = 0;
  bool _isAddingToBag = false;
  bool _isWishlisted = false;
  late AnimationController _stampController;
  late Animation<double> _stampScale;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stampScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  void _addToBag() async {
    setState(() => _isAddingToBag = true);
    _stampController.forward().then((_) => _stampController.reverse());
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isAddingToBag = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Added to Shopping Bag!'),
            ],
          ),
          backgroundColor: context.colors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInStock = widget.productId != '4';

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsing image header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.colors.surface,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8),
                  ],
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: context.colors.textPrimary),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: context.colors.textPrimary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sharing link copied!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: context.colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: context.colors.error,
                  ),
                  onPressed: () {
                    setState(() => _isWishlisted = !_isWishlisted);
                    if (_isWishlisted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Added to Wishlist!'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: context.colors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Removed from Wishlist'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image area
                  Container(
                    color: const Color(0xFFF1F3F4),
                    child: const Center(
                      child: Icon(Icons.edit_rounded,
                          size: 100, color: Color(0xFFBEC3C8)),
                    ),
                  ),
                  // Image pagination dots
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedImage = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _selectedImage == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _selectedImage == i
                                  ? context.colors.primary
                                  : context.colors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isInStock
                              ? context.colors.success.withValues(alpha: 0.1)
                              : context.colors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInStock
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 12,
                              color: isInStock
                                  ? context.colors.success
                                  : context.colors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isInStock ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isInStock
                                    ? context.colors.success
                                    : context.colors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '29% OFF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    'Parker Sonnet Special Edition\nFountain Pen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating Summary (Clickable to Reviews Screen)
                  GestureDetector(
                    onTap: () => context.push('/catalog/product/${widget.productId}/reviews'),
                    child: Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '4.8  •  124 reviews',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Rate Product Button
                  GestureDetector(
                    onTap: () => context.push('/catalog/product/${widget.productId}/rate'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: context.colors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Rate Product',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    children: [
                      Text(
                        '₹4,500',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.colors.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '₹6,300',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Product Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A classic expression of refined style, Sonnet is Parker\'s symbol of elegance. Outstanding performance meets timeless design. Features a 18K gold nib, lacquered barrel, and palladium-plated trim. Perfect for executives and collectors alike.\n\nIncludes converter for ink bottle use or standard cartridges.',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specifications
                  Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  _SpecRow('Nib Material', '18K Gold'),
                  _SpecRow('Barrel', 'Lacquered Metal'),
                  _SpecRow('Filling System', 'Converter / Cartridge'),
                  _SpecRow('Weight', '28g'),
                  _SpecRow('SKU', 'PK-SN-SE-01'),

                  const SizedBox(height: 120), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Add-to-Bag bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: isInStock
            ? ScaleTransition(
                scale: _stampScale,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: _isAddingToBag
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: Text(_isAddingToBag ? 'Adding...' : 'Add to Bag'),
                    onPressed: _isAddingToBag ? null : _addToBag,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: context.colors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Currently Out of Stock. Contact us for availability.',
                            style: TextStyle(
                              color: context.colors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colors.primary),
                      ),
                      icon: Icon(Icons.phone_rounded,
                          size: 18, color: context.colors.primary),
                      label: Text('+91 98765 43210'),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: ProductDetailScreen.shopPhone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}






