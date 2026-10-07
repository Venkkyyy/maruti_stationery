import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagePaymentMethodsScreen extends StatelessWidget {
  const ManagePaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text('Payment Methods',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.colors.primary,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: context.colors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment methods are selected securely at checkout. We support UPI, Credit/Debit Cards, Net Banking, and Cash on Delivery.',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.colors.primary,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Accepted Payment Methods',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 12),

            _PaymentMethodTile(
              icon: Icons.payment_rounded,
              title: 'UPI',
              subtitle: 'Google Pay, PhonePe, Paytm & more',
              color: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 8),
            _PaymentMethodTile(
              icon: Icons.credit_card_rounded,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay & more',
              color: const Color(0xFF1B2D6E),
            ),
            const SizedBox(height: 8),
            _PaymentMethodTile(
              icon: Icons.account_balance_rounded,
              title: 'Net Banking',
              subtitle: 'All major Indian banks supported',
              color: const Color(0xFF34A853),
            ),
            const SizedBox(height: 8),
            _PaymentMethodTile(
              icon: Icons.money_rounded,
              title: 'Cash on Delivery',
              subtitle: 'Pay at your doorstep',
              color: const Color(0xFFB45309),
            ),

            const SizedBox(height: 32),

            // Security note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded,
                        color: context.colors.success, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('100% Secure Payments',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: context.colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'All transactions are encrypted and secured by Razorpay.',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.colors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: context.colors.success, size: 20),
        ],
      ),
    );
  }
}
