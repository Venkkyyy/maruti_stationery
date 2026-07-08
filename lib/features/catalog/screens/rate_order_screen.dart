import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                return _buildProductFeedbackCard(
                  product.name, 
                  AppFormatters.formatPrice(product.price),
                  product.primaryImage,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildProductFeedbackCard(String title, String price, String imageUrl) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.colors.surfaceGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: imageUrl.isNotEmpty 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, fit: BoxFit.cover)
                  )
                : Icon(Icons.inventory_2_outlined, color: context.colors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(price, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < _mainRating ? Icons.star_rounded : Icons.star_border_rounded, 
                          size: 16, 
                          color: index < _mainRating ? context.colors.primary : context.colors.border,
                        )),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: context.colors.divider),
      ],
    );
  }
}

