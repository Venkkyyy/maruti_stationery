import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../core/utils/formatters.dart';

class RateOrderScreen extends ConsumerStatefulWidget {
  final String productId;
  const RateOrderScreen({super.key, required this.productId});

  @override
  ConsumerState<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends ConsumerState<RateOrderScreen> {
  int _mainRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Rate Your Order', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text('How was your experience?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Tap a star to rate your overall satisfaction', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _mainRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: index < _mainRating ? context.colors.primary : context.colors.border,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _mainRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 32),
            Text('PRODUCT FEEDBACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            
            ref.watch(watchProductProvider(widget.productId)).when(
              data: (product) {
                if (product == null) return const SizedBox.shrink();
                return _buildProductFeedbackCard(product);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),
            Text('Write your review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Share your thoughts with other customers.', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'What did you like or dislike about the product?',
                  hintStyle: TextStyle(fontSize: 14, color: context.colors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: context.colors.textHint, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -2))],
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_mainRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a rating'), backgroundColor: context.colors.error),
                  );
                  return;
                }
                
                setState(() => _isSubmitting = true);
                try {
                  await ref.read(reviewProvider.notifier).addReview(
                    widget.productId,
                    _mainRating,
                    _reviewController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Review submitted successfully!'), backgroundColor: context.colors.primary),
                    );
                    context.pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductFeedbackCard(dynamic product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: context.colors.surfaceGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.primaryImage.isNotEmpty 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.primaryImage, 
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    placeholder: (context, url) => Container(color: context.colors.surfaceGrey),
                    errorWidget: (context, url, error) => Icon(Icons.inventory_2_outlined, color: context.colors.primary, size: 24),
                  )
                )
              : Icon(Icons.inventory_2_outlined, color: context.colors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(AppFormatters.formatPrice(product.price), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < _mainRating ? Icons.star_rounded : Icons.star_border_rounded, 
                    size: 16, 
                    color: index < _mainRating ? Colors.amber : context.colors.border,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () async {
              try {
                await ref.read(cartProvider.notifier).addItem(product, 1);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('${product.name} added to cart!'),
                        ],
                      ),
                      backgroundColor: context.colors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: context.colors.error),
                  );
                }
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: context.colors.primaryLight,
              foregroundColor: context.colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
        ],
      ),
    );
  }
}

