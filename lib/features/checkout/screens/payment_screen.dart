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
import '../../../services/local_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPayment = 'gpay';

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final cartItems = ref.watch(cartProvider).value ?? [];
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final subtotal = cartNotifier.subtotal;
    final discount = appliedCoupon?.calculateDiscount(subtotal) ?? 0;
    final deliveryCharge = 0; // Or whatever your delivery logic is
    final totalAmount = subtotal + deliveryCharge - discount;
    final addresses = ref.watch(addressProvider).value ?? [];
    final selectedAddress = addresses.isNotEmpty ? addresses.first : null;

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
        title: const Text('Maruti Stationery', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A73E8), fontSize: 18)),
        actions: [
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: context.colors.success),
              const SizedBox(width: 4),
              Text('Secure', style: TextStyle(color: context.colors.success, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 16),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalHeader(totalAmount, cartItems, appliedCoupon),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        const SizedBox(height: 16),
                        
                        Text('UPI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedPayment.contains('pay') ? context.colors.primary : context.colors.border),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentOption('gpay', 'Google Pay', Icons.payment),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('phonepe', 'PhonePe', Icons.account_balance_wallet),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('paytm', 'Paytm', Icons.qr_code),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Text('CARDS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedPayment == 'card' ? context.colors.primary : context.colors.border),
                          ),
                          child: _buildPaymentOption('card', 'Credit / Debit Card', Icons.credit_card, subtitle: 'Visa, Mastercard, RuPay & more'),
                        ),

                        const SizedBox(height: 24),
                        Text('OTHER OPTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ['netbanking', 'cod'].contains(_selectedPayment) ? context.colors.primary : context.colors.border),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentOption('netbanking', 'Netbanking', Icons.account_balance),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('cod', 'Cash on Delivery', Icons.money, subtitle: 'Pay at your doorstep'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.security, size: 16, color: context.colors.success),
                            const SizedBox(width: 4),
                            Text('100% Secure Checkout   |   Powered by Razorpay', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
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
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (cartItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Your cart is empty!')),
                  );
                  return;
                }
                
                final user = ref.read(authStateProvider).value;
                final userId = user?.uid;
                final userEmail = user?.email;
                if (userId == null) return;
                
                if (selectedAddress == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please add an address first!')),
                  );
                  return;
                }
                
                // Construct OrderModel
                final order = OrderModel(
                  id: const Uuid().v4(),
                  userId: userId,
                  status: OrderStatus.placed,
                  items: cartItems.map((item) => OrderItem(
                    productId: item.productId,
                    name: item.name,
                    image: item.image,
                    price: item.price,
                    qty: item.qty,
                    unit: 'piece',
                  )).toList(),
                  address: selectedAddress,
                  subtotal: subtotal,
                  deliveryCharge: deliveryCharge,
                  discount: discount,
                  total: totalAmount,
                  paymentMethod: PaymentMethod.values.firstWhere(
                    (e) => e.name == _selectedPayment, 
                    orElse: () => PaymentMethod.upi,
                  ),
                  paymentStatus: _selectedPayment == 'cod' ? PaymentStatus.pending : PaymentStatus.paid,
                  idempotencyKey: const Uuid().v4(),
                  createdAt: DateTime.now(),
                );
                
                try {
                  // Show loading
                  showDialog(
                    context: context, 
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  // Save order
                  await ref.read(orderServiceProvider).createOrder(order);
                  
                  // Clear cart and coupons
                  await cartNotifier.clearCart();
                  ref.read(appliedCouponProvider.notifier).removeCoupon();
                  
                  // Trigger local notification
                  LocalNotificationService.showNotification(
                    id: 0,
                    title: 'Order Placed Successfully! 🎉',
                    body: 'Your order of ₹${(totalAmount / 100).toStringAsFixed(2)} has been placed.',
                  );
                  
                  // Pop loading dialog
                  if (context.mounted) Navigator.pop(context);
                  
                  // Navigate to confirmation
                  if (context.mounted) context.go('/checkout/confirmation', extra: order.id);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Pay Now ${AppFormatters.formatPrice(totalAmount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHeader(int totalAmount, List<dynamic> cartItems, dynamic appliedCoupon) {
    final subtotal = cartItems.fold<int>(0, (sum, item) => sum + (item.price * item.qty) as int);
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount to Pay', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
              const SizedBox(height: 4),
              Text(AppFormatters.formatPrice(totalAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
            ],
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: context.colors.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price (${cartItems.length} items)', style: TextStyle(color: context.colors.textSecondary)),
                            Text(AppFormatters.formatPrice(cartItems.fold<int>(0, (sum, item) => sum + (item.price * item.qty) as int))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Delivery Charges', style: TextStyle(color: context.colors.textSecondary)),
                            Text('FREE', style: TextStyle(color: context.colors.success)),
                          ],
                        ),
                        if (appliedCoupon != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Coupon Discount', style: TextStyle(color: context.colors.textSecondary)),
                              Text('-${AppFormatters.formatPrice(appliedCoupon.calculateDiscount(subtotal))}', style: TextStyle(color: context.colors.success)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
                            Text(AppFormatters.formatPrice(totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              );
            },
            child: const Text('View Details ?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A73E8))),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String id, String title, IconData icon, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: _selectedPayment == id ? context.colors.primary : context.colors.textSecondary),
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
}

