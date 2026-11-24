import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../../models/address_model.dart';
import '../../../models/cart_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/local_notification_service.dart';

enum _StepState { completed, active, upcoming }

class PaymentScreen extends ConsumerStatefulWidget {
  final String? selectedAddressId;

  const PaymentScreen({super.key, this.selectedAddressId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPayment = 'cod';
  bool _useLoyaltyPoints = false;
  bool _isPlacingOrder = false;
  String? _currentAddressId;

  @override
  void initState() {
    super.initState();
    _currentAddressId = widget.selectedAddressId;
  }

  void _openAddressSelector(List<AddressModel> addresses) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Delivery Address',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkDark,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No saved addresses found.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: addresses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final addr = addresses[i];
                          final isSelected = _currentAddressId == addr.id ||
                              (_currentAddressId == null && i == 0);

                          return InkWell(
                            onTap: () {
                              setState(() => _currentAddressId = addr.id);
                              context.pop();
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.royalBlue.withValues(alpha: 0.04)
                                    : AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.royalBlue
                                      : AppColors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected
                                        ? AppColors.royalBlue
                                        : AppColors.textHint,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addr.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.inkDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${addr.street}, ${addr.city} - ${addr.pincode}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        context.push('/checkout/address/add');
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Add New Address',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.royalBlue,
                        side: const BorderSide(
                          color: AppColors.royalBlue,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _placeOrder({
    required List<CartItemModel> cartItems,
    required AddressModel? selectedAddress,
    required int subtotal,
    required int deliveryCharge,
    required int discount,
    required int loyaltyDiscountPaise,
    required int totalAmount,
    required int pointsToDeduct,
  }) async {
    if (_isPlacingOrder) return;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    final userId = user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final now = DateTime.now();
      final datePart =
          '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final randomPart = const Uuid().v4().substring(0, 5).toUpperCase();
      final customOrderId = 'MARUTI$datePart${randomPart}ST';

      PaymentMethod method = PaymentMethod.cod;
      if (_selectedPayment == 'upi') {
        method = PaymentMethod.upi;
      } else if (_selectedPayment == 'card') {
        method = PaymentMethod.card;
      }

      final order = OrderModel(
        id: customOrderId,
        userId: userId,
        status: OrderStatus.placed,
        items: cartItems
            .map((item) => OrderItem(
                  productId: item.productId,
                  name: item.name,
                  image: item.image,
                  price: item.price,
                  qty: item.qty,
                  unit: 'piece',
                  selectedVariations: item.selectedVariations,
                ))
            .toList(),
        address: selectedAddress,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge,
        discount: discount + loyaltyDiscountPaise,
        total: totalAmount,
        paymentMethod: method,
        paymentStatus: PaymentStatus.pending,
        idempotencyKey: const Uuid().v4(),
        pointsUsed: pointsToDeduct,
        deliveryCode: (Random().nextInt(900000) + 100000).toString(),
        createdAt: DateTime.now(),
      );

      // Create order in Firestore transaction
      final pointsEarned =
          await ref.read(orderServiceProvider).createOrder(order);

      // Clear cart & coupons
      await ref.read(cartProvider.notifier).clearCart();
      ref.read(appliedCouponProvider.notifier).removeCoupon();

      // Trigger local notification (safe fallback if notifications disabled)
      try {
        final productSummary = cartItems.take(2).map((i) => i.name).join(', ') +
            (cartItems.length > 2 ? ' and ${cartItems.length - 2} more' : '');

        await LocalNotificationService.showNotification(
          id: 0,
          title: 'Order Placed Successfully! 🎉',
          body: 'Your order for $productSummary has been received.',
        );
      } catch (_) {}

      if (mounted) {
        context.go(
          '/checkout/confirmation',
          extra: {'orderId': order.id, 'pointsEarned': pointsEarned},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final cartItems = ref.watch(cartProvider).value ?? [];
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final deliverySettings =
        ref.watch(watchDeliverySettingsProvider).value ??
        const DeliverySettingsModel();

    final subtotal = cartNotifier.subtotal;
    final isFreeDeliveryCoupon = appliedCoupon?.discountType == 'free_delivery';
    final isFreeDelivery =
        isFreeDeliveryCoupon || subtotal >= deliverySettings.freeThreshold;
    final deliveryCharge = isFreeDelivery ? 0 : deliverySettings.fee;
    final discount = isFreeDeliveryCoupon
        ? 0
        : (appliedCoupon?.calculateDiscount(subtotal) ?? 0);
    final totalBeforePoints =
        (subtotal + deliveryCharge - discount).clamp(0, double.maxFinite).toInt();

    final userModel = ref.watch(currentUserModelProvider).value;
    final loyaltyRule =
        ref.watch(watchLoyaltyRuleProvider).value ?? const LoyaltyRuleModel();

    final int availablePoints = userModel?.loyaltyPoints ?? 0;
    int loyaltyDiscountPaise = 0;
    int pointsToDeduct = 0;
    if (_useLoyaltyPoints && availablePoints >= loyaltyRule.pointsToRupeeRatio) {
      final maxRupeesOff = availablePoints ~/ loyaltyRule.pointsToRupeeRatio;
      loyaltyDiscountPaise = maxRupeesOff * 100;
      if (loyaltyDiscountPaise > totalBeforePoints) {
        loyaltyDiscountPaise = totalBeforePoints;
      }
      pointsToDeduct =
          (loyaltyDiscountPaise ~/ 100) * loyaltyRule.pointsToRupeeRatio;
    }

    final totalAmount = totalBeforePoints - loyaltyDiscountPaise;

    final addresses = ref.watch(addressProvider).value ?? [];
    final selectedAddress = _currentAddressId != null
        ? addresses.where((a) => a.id == _currentAddressId).firstOrNull
        : addresses.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/cart');
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.inkDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── 1. Three-Step Progress Stepper ────────────────────────
          _buildCheckoutStepper(),

          // ── Scrollable Body ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 2. Delivery Address Card (Matching Screen 9) ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkDark,
                              ),
                            ),
                            InkWell(
                              onTap: () => _openAddressSelector(addresses),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedAddress != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.royalBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedAddress.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${selectedAddress.street}, ${selectedAddress.city}, ${selectedAddress.state} - ${selectedAddress.pincode}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: () => context.push('/checkout/address/add'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Delivery Address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 3. Payment Methods (Matching Screen 9) ────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkDark,
                            ),
                          ),
                        ),
                        _buildPaymentTile(
                          id: 'upi',
                          title: 'UPI',
                          subtitle: 'Google Pay, PhonePe, Paytm, etc.',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const Divider(
                          color: AppColors.border,
                          height: 1,
                          indent: 56,
                        ),
                        _buildPaymentTile(
                          id: 'card',
                          title: 'Razorpay',
                          subtitle: 'Cards, Net Banking, UPI',
                          icon: Icons.credit_card_outlined,
                        ),
                        const Divider(
                          color: AppColors.border,
                          height: 1,
                          indent: 56,
                        ),
                        _buildPaymentTile(
                          id: 'cod',
                          title: 'Cash on Delivery',
                          subtitle: 'Pay at your doorstep',
                          icon: Icons.money_rounded,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // ── 4. Loyalty Points Redemption (Optional) ───────
                  if (availablePoints >= loyaltyRule.pointsToRupeeRatio) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: _useLoyaltyPoints,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() => _useLoyaltyPoints = val ?? false);
                        },
                        title: Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Redeem Loyalty Points',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.inkDark,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'You have $availablePoints pts. Save ${AppFormatters.formatPrice(loyaltyDiscountPaise > 0 ? loyaltyDiscountPaise : (availablePoints ~/ loyaltyRule.pointsToRupeeRatio) * 100)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── 5. Compact Product Preview ────────────────────
                  if (cartItems.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items (${cartItems.length})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkDark,
                                ),
                              ),
                              Text(
                                '${cartItems.fold<int>(0, (s, i) => s + i.qty)} total units',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: cartItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final item = cartItems[i];
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWarm,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.image.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.image,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                Container(
                                              color: AppColors.surfaceWarm,
                                            ),
                                            errorWidget:
                                                (context, url, err) =>
                                                    const Icon(
                                              Icons.auto_stories_rounded,
                                              size: 20,
                                              color: AppColors.textHint,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.auto_stories_rounded,
                                            size: 20,
                                            color: AppColors.textHint,
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── 6. Order Summary Card (Matching Screen 9) ─────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _summaryRow(
                          'Items (${cartItems.length})',
                          AppFormatters.formatPrice(subtotal),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 10),
                          _summaryRow(
                            'Coupon Discount',
                            '- ${AppFormatters.formatPrice(discount)}',
                            valueColor: const Color(0xFF1E9A4B),
                            isBold: true,
                          ),
                        ],
                        if (_useLoyaltyPoints &&
                            loyaltyDiscountPaise > 0) ...[
                          const SizedBox(height: 10),
                          _summaryRow(
                            'Loyalty Points',
                            '- ${AppFormatters.formatPrice(loyaltyDiscountPaise)}',
                            valueColor: const Color(0xFF1E9A4B),
                            isBold: true,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _summaryRow(
                          'Delivery Charges',
                          isFreeDelivery
                              ? 'FREE'
                              : AppFormatters.formatPrice(deliveryCharge),
                          valueColor: isFreeDelivery
                              ? const Color(0xFF1E9A4B)
                              : AppColors.inkDark,
                          isBold: isFreeDelivery,
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkDark,
                              ),
                            ),
                            Text(
                              AppFormatters.formatPrice(totalAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.inkDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 7. Trust Security Badge ───────────────────────
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: AppColors.royalBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '100% Secure & Verified Payments',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── 8. Fixed Bottom Place Order CTA (Matching Screen 9) ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder
                      ? null
                      : () => _placeOrder(
                            cartItems: cartItems,
                            selectedAddress: selectedAddress,
                            subtotal: subtotal,
                            deliveryCharge: deliveryCharge,
                            discount: discount,
                            loyaltyDiscountPaise: loyaltyDiscountPaise,
                            totalAmount: totalAmount,
                            pointsToDeduct: pointsToDeduct,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Checkout Stepper Widget ────────────────────────────────────────
  Widget _buildCheckoutStepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1: Address (Done)
          _buildStepItem(
            stepNumber: '1',
            label: 'Address',
            state: _StepState.completed,
          ),
          _buildStepLine(isCompleted: true),
          // Step 2: Payment (Active)
          _buildStepItem(
            stepNumber: '2',
            label: 'Payment',
            state: _StepState.active,
          ),
          _buildStepLine(isCompleted: false),
          // Step 3: Review (Upcoming)
          _buildStepItem(
            stepNumber: '3',
            label: 'Review',
            state: _StepState.upcoming,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String label,
    required _StepState state,
  }) {
    Color circleColor;
    Color textColor;
    Color labelColor;

    switch (state) {
      case _StepState.completed:
        circleColor = AppColors.royalBlue;
        textColor = Colors.white;
        labelColor = AppColors.royalBlue;
        break;
      case _StepState.active:
        circleColor = AppColors.primary;
        textColor = Colors.white;
        labelColor = AppColors.primary;
        break;
      case _StepState.upcoming:
        circleColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF94A3B8);
        labelColor = const Color(0xFF94A3B8);
        break;
    }

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: state == _StepState.upcoming
                ? Border.all(color: const Color(0xFFCBD5E1), width: 1.2)
                : null,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isCompleted}) {
    return Container(
      width: 48,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
      color: isCompleted ? AppColors.royalBlue : const Color(0xFFE2E8F0),
    );
  }

  // ── Payment Tile ──────────────────────────────────────────────────
  Widget _buildPaymentTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPayment == id;

    return InkWell(
      onTap: () => setState(() => _selectedPayment = id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.royalBlue.withValues(alpha: 0.08)
                    : AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.royalBlue : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedPayment,
              activeColor: AppColors.royalBlue,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPayment = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Row Helper ────────────────────────────────────────────
  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.inkDark,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
