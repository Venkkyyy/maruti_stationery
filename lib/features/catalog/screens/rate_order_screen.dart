import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RateOrderScreen extends StatefulWidget {
  final String productId;
  const RateOrderScreen({super.key, required this.productId});

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  int _mainRating = 0;

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
            
            _buildProductFeedbackCard('Parker Vector Rollerball Pen', '₹450.00'),
            const SizedBox(height: 16),
            _buildProductFeedbackCard('Moleskine Classic Notebook', '₹1,250.00'),

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
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'What did you like or dislike about the products?',
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
              onPressed: () {
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductFeedbackCard(String title, String price) {
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
              child: Icon(Icons.edit, color: context.colors.primary, size: 24),
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
                        children: List.generate(5, (index) => Icon(Icons.star_border_rounded, size: 16, color: context.colors.border)),
                      ),
                      const Spacer(),
                      Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.primary)),
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

