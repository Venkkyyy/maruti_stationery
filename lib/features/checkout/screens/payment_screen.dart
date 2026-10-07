import 'dart:math';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/cart_provider.dart';
import '../../../core/utils/formatters.dart';
import 'package:uuid/uuid.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/local_notification_service.dart';
class PaymentScreen extends ConsumerStatefulWidget {
  final String? selectedAddressId;
  const PaymentScreen({super.key, this.selectedAddressId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPayment = 'cod';
  bool _useLoyaltyPoints = false;

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final cartItems = ref.watch(cartProvider).value ?? [];
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final deliverySettings = ref.watch(watchDeliverySettingsProvider).value ?? const DeliverySettingsModel();
    
    final subtotal = cartNotifier.subtotal;
    
    final isFreeDeliveryCoupon = appliedCoupon?.discountType == 'free_delivery';
    final isFreeDelivery = isFreeDeliveryCoupon || subtotal >= deliverySettings.freeThreshold;
    final deliveryCharge = isFreeDelivery ? 0 : deliverySettings.fee;
    
    final discount = isFreeDeliveryCoupon ? 0 : (appliedCoupon?.calculateDiscount(subtotal) ?? 0);
    final totalBeforePoints = (subtotal + deliveryCharge - discount).clamp(0, double.maxFinite).toInt();

    final userModel = ref.watch(currentUserModelProvider).value;
    final loyaltyRule = ref.watch(watchLoyaltyRuleProvider).value ?? const LoyaltyRuleModel();
    
    final int availablePoints = userModel?.loyaltyPoints ?? 0;
    int loyaltyDiscountPaise = 0;
    int pointsToDeduct = 0;
    if (_useLoyaltyPoints && availablePoints >= loyaltyRule.pointsToRupeeRatio) {
      final maxRupeesOff = availablePoints ~/ loyaltyRule.pointsToRupeeRatio;
      loyaltyDiscountPaise = maxRupeesOff * 100;
      
      if (loyaltyDiscountPaise > totalBeforePoints) {
        loyaltyDiscountPaise = totalBeforePoints;
      }
      pointsToDeduct = (loyaltyDiscountPaise ~/ 100) * loyaltyRule.pointsToRupeeRatio;
    }
    
    final totalAmount = totalBeforePoints - loyaltyDiscountPaise;

    final addresses = ref.watch(addressProvider).value ?? [];
    // Use the address selected in the address screen; fall back to first
    final selectedAddress = widget.selectedAddressId != null 
        ? addresses.where((a) => a.id == widget.selectedAddressId).firstOrNull
        : addresses.firstOrNull;

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
              context.go('/cart');
            }
          },
        ),
        title: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.textPrimary, fontSize: 18)),
      ),
      body: Column(
        children: [
          _CheckoutStepper(step: 2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentOption('upi', 'UPI (PhonePe, GPay, Paytm)', null),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('card', 'Credit / Debit Card', Icons.credit_card, subtitle: '**** 4582                               VISA'),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('netbanking', 'Net Banking', Icons.account_balance),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('cod', 'Cash on Delivery', Icons.money),
                            ],
                          ),
                        ),
                        if (availablePoints >= loyaltyRule.pointsToRupeeRatio) ...[
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: CheckboxListTile(
                              value: _useLoyaltyPoints,
                              activeColor: context.colors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _useLoyaltyPoints = val ?? false;
                                });
                              },
                              title: Row(
                                children: [
                                  Icon(Icons.stars_rounded, color: context.colors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Use Loyalty Points',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'You have $availablePoints points.\n${loyaltyRule.pointsToRupeeRatio} Points = ₹1 off.',
                                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                              ),
                              secondary: _useLoyaltyPoints && loyaltyDiscountPaise > 0
                                  ? Text(
                                      '- ${AppFormatters.formatPrice(loyaltyDiscountPaise)}',
                                      style: TextStyle(
                                        color: context.colors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Price Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.colors.textPrimary)),
                              const SizedBox(height: 16),
                              _priceRow('Subtotal', AppFormatters.formatPrice(subtotal)),
                              if (discount > 0) ...[
                                const SizedBox(height: 12),
                                _priceRow('Coupon Discount', '- ${AppFormatters.formatPrice(discount)}', isGreen: true),
                              ],
                              if (_useLoyaltyPoints && loyaltyDiscountPaise > 0) ...[
                                const SizedBox(height: 12),
                                _priceRow('Loyalty Points Discount', '- ${AppFormatters.formatPrice(loyaltyDiscountPaise)}', isGreen: true),
                              ],
                              const SizedBox(height: 12),
                              _priceRow(
                                'Shipping', 
                                isFreeDelivery ? 'FREE' : AppFormatters.formatPrice(deliveryCharge), 
                                isGreen: isFreeDelivery,
                              ),
                              const SizedBox(height: 16),
                              Divider(color: context.colors.border.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
                                  Text(AppFormatters.formatPrice(totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.colors.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded, size: 14, color: context.colors.textSecondary),
                            const SizedBox(width: 4),
                            Text('100% secure payments powered by Razorpay', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () async {
                if (cartItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Your cart is empty!')),
                  );
                  return;
                }
                
                final user = ref.read(authStateProvider).value;
                final userId = user?.uid;
                if (userId == null) return;
                
                if (selectedAddress == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add an address first!')),
                  );
                  return;
                }
                
                final now = DateTime.now();
                final datePart = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
                final randomPart = const Uuid().v4().substring(0, 5).toUpperCase();
                final customOrderId = 'MARUTI$datePart${randomPart}ST';

                // Construct OrderModel
                final order = OrderModel(
                  id: customOrderId,
                  userId: userId,
                  status: OrderStatus.placed,
                  items: cartItems.map((item) => OrderItem(
                    productId: item.productId,
                    name: item.name,
                    image: item.image,
                    price: item.price,
                    qty: item.qty,
                    unit: 'piece',
                    selectedVariations: item.selectedVariations,
                  )).toList(),
                  address: selectedAddress,
                  subtotal: subtotal,
                  deliveryCharge: deliveryCharge,
                  discount: discount + loyaltyDiscountPaise,
                  total: totalAmount,
                  paymentMethod: PaymentMethod.values.firstWhere(
                    (e) => e.name == _selectedPayment,
                    orElse: () => PaymentMethod.cod,
                  ),
                  // All methods pending until Razorpay is integrated
                  paymentStatus: PaymentStatus.pending,
                  idempotencyKey: const Uuid().v4(),
                  pointsUsed: pointsToDeduct,
                  deliveryCode: (Random().nextInt(900000) + 100000).toString(),
                  createdAt: DateTime.now(),
                );
                
                try {
                  // Show loading
                  showDialog(
                    context: context, 
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  // Save order and get points earned
                  final pointsEarned = await ref.read(orderServiceProvider).createOrder(order);
                  
                  // Clear cart and coupons
                  await cartNotifier.clearCart();
                  ref.read(appliedCouponProvider.notifier).removeCoupon();
                  
                  // Extract product names
                  final productNames = cartItems.take(2).map((item) => item.name).join(', ') + 
                      (cartItems.length > 2 ? ' and ${cartItems.length - 2} more' : '');
                  
                  // Trigger local notification
                  LocalNotificationService.showNotification(
                    id: 0,
                    title: 'Order Placed Successfully! 🎉',
                    body: 'Your order for $productNames has been placed.',
                  );
                  
                  // Pop loading dialog
                  if (context.mounted) Navigator.pop(context);
                  
                  // Navigate to confirmation — pass both orderId and pointsEarned
                  if (context.mounted) context.go('/checkout/confirmation', extra: {'orderId': order.id, 'pointsEarned': pointsEarned});
                } catch (e) {
                  // Pop loading dialog
                  if (context.mounted) Navigator.pop(context);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text('Continue to Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String id, String title, IconData? icon, {String? subtitle}) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: _selectedPayment == id ? context.colors.primary : context.colors.textSecondary) : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Radio<String>(
        value: id,
        groupValue: _selectedPayment,
        activeColor: context.colors.primary,
        onChanged: (val) {
          setState(() {
            _selectedPayment = val!;
          });
        },
      ),
      onTap: () {
        setState(() {
          _selectedPayment = id;
        });
      },
    );
  }

  Widget _priceRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            color: isGreen ? context.colors.success : context.colors.textPrimary,
            fontSize: 14,
            fontWeight: isGreen ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Checkout Stepper (shared) ──────────────────────────────────────────────

class _CheckoutStepper extends StatelessWidget {
  final int step; // 1=Address, 2=Payment, 3=Confirm

  const _CheckoutStepper({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _StepDot(number: 1, label: 'Address', isActive: step >= 1, isDone: step > 1),
          _StepLine(isActive: step > 1),
          _StepDot(number: 2, label: 'Payment', isActive: step >= 2, isDone: step > 2),
          _StepLine(isActive: step > 2),
          _StepDot(number: 3, label: 'Review', isActive: step >= 3, isDone: step > 3),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? context.colors.primary : context.colors.surfaceGrey,
            border: Border.all(
              color: isActive ? context.colors.primary : context.colors.border,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : context.colors.textHint,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? context.colors.primary : context.colors.textHint,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: isActive ? context.colors.primary : context.colors.border,
      ),
    );
  }
}

