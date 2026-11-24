import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../../models/return_request_model.dart';
import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  void _showAddressDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final address = order.address;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
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
                          address.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkDark,
                          ),
                        ),
                        if (address.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            address.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${address.street}\n${address.city}, ${address.state} - ${address.pincode}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.inkDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _confirmCancelOrder(BuildContext context, OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.inkDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'No, Keep Order',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OrderService().cancelOrder(order.id, order.userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(watchOrderProvider(orderId));

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
                  context.go('/home');
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
          'Track Order',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load order: $err',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text(
                'Order not found.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final orderShortId = order.id.length > 8
              ? order.id.substring(0, 8).toUpperCase()
              : order.id.toUpperCase();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Order Summary Card (Matching Mockup Screen 8) ──
                Container(
                  padding: const EdgeInsets.all(14),
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
                  child: Row(
                    children: [
                      // Circular Icon Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: order.status == OrderStatus.delivered
                              ? const Color(0xFFEAF8EF)
                              : (order.status == OrderStatus.cancelled
                                  ? const Color(0xFFFEE2E2)
                                  : AppColors.royalBlue.withValues(alpha: 0.08)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            order.status == OrderStatus.delivered
                                ? Icons.verified_rounded
                                : (order.status == OrderStatus.cancelled
                                    ? Icons.cancel_rounded
                                    : Icons.inventory_2_rounded),
                            size: 22,
                            color: order.status == OrderStatus.delivered
                                ? const Color(0xFF1E9A4B)
                                : (order.status == OrderStatus.cancelled
                                    ? AppColors.error
                                    : AppColors.royalBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Order ID & Placed Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #MS$orderShortId',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Placed on ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      _buildStatusPill(order.status),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── 2. Ordered Items Snapshot ───────────────────────
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.5),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.image.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.image,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            Container(color: AppColors.surfaceWarm),
                                        errorWidget: (context, url, err) =>
                                            const Icon(
                                          Icons.auto_stories_rounded,
                                          size: 24,
                                          color: AppColors.textHint,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.auto_stories_rounded,
                                        size: 24,
                                        color: AppColors.textHint,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.selectedVariations.isNotEmpty
                                        ? item.selectedVariations.values.join(' • ')
                                        : '${item.unit != 'piece' ? item.unit : 'Standard'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppFormatters.formatPrice(item.price)} × ${item.qty}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.inkDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                const SizedBox(height: 6),

                // ── 3. Delivery Verification Code (if active) ───────
                if (order.deliveryCode != null &&
                    order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled &&
                    order.status != OrderStatus.returned) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1EB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFCD8C6)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Delivery Verification Code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.deliveryCode!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Share this 6-digit code with the delivery partner upon arrival.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 4. Order Progress Timeline (Matching Screen 8) ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                        'Order Status Timeline',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (order.status == OrderStatus.cancelled) ...[
                        _buildTimelineStep(
                          title: 'Order Placed',
                          subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                          isCompleted: true,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Order Cancelled',
                          subtitle: 'This order has been cancelled.',
                          isCompleted: false,
                          isCancelled: true,
                          isLast: true,
                        ),
                      ] else if (order.status == OrderStatus.returned) ...[
                        _buildTimelineStep(
                          title: 'Order Placed',
                          subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                          isCompleted: true,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Delivered',
                          subtitle: order.deliveredAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(order.deliveredAt!)
                              : 'Delivered to address',
                          isCompleted: true,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Returned',
                          subtitle: 'Return accepted and processed.',
                          isCompleted: true,
                          isLast: true,
                        ),
                      ] else ...[
                        // Step 1: Placed
                        _buildTimelineStep(
                          title: 'Order Placed',
                          subtitle: DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                          isCompleted: order.status.index >= OrderStatus.placed.index,
                          isCurrent: order.status == OrderStatus.placed,
                          isLast: false,
                        ),
                        // Step 2: Packed
                        _buildTimelineStep(
                          title: 'Packed',
                          subtitle: order.status.index >= OrderStatus.packed.index
                              ? 'Items carefully inspected and packed'
                              : 'Seller is preparing your order',
                          isCompleted: order.status.index >= OrderStatus.packed.index,
                          isCurrent: order.status == OrderStatus.confirmed ||
                              order.status == OrderStatus.packed,
                          isLast: false,
                        ),
                        // Step 3: Shipped
                        _buildTimelineStep(
                          title: 'Shipped',
                          subtitle: order.status.index >= OrderStatus.shipped.index
                              ? 'Package has left our local facility'
                              : 'Ready for courier dispatch',
                          isCompleted: order.status.index >= OrderStatus.shipped.index,
                          isCurrent: order.status == OrderStatus.shipped,
                          isLast: false,
                        ),
                        // Step 4: Out for Delivery
                        _buildTimelineStep(
                          title: 'Out for Delivery',
                          subtitle: order.status.index >= OrderStatus.shipped.index &&
                                  order.status != OrderStatus.delivered
                              ? 'Driver is on the way to your location'
                              : (order.status == OrderStatus.delivered
                                  ? 'Arrived at your doorstep'
                                  : 'Pending local dispatch'),
                          isCompleted: order.status == OrderStatus.delivered,
                          isCurrent: order.status == OrderStatus.shipped,
                          isLast: false,
                        ),
                        // Step 5: Delivered
                        _buildTimelineStep(
                          title: 'Delivered',
                          subtitle: order.deliveredAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(order.deliveredAt!)
                              : (order.status == OrderStatus.delivered
                                  ? 'Delivered successfully'
                                  : 'Expected soon'),
                          isCompleted: order.status == OrderStatus.delivered,
                          isCurrent: false,
                          isLast: true,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── 5. Delivery Address Card (Matching Screen 8 Bottom) ─
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  child: Row(
                    children: [
                      // Delivery Vehicle Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.royalBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Destination
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivered to',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.address.street}, ${order.address.city}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // View Details action
                      InkWell(
                        onTap: () => _showAddressDetails(context, order),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.royalBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── 6. Payment & Price Breakdown Card ─────────────────
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
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            order.paymentMethod.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Status',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            order.paymentStatus == PaymentStatus.paid ||
                                    order.paymentMethod != PaymentMethod.cod
                                ? 'PAID'
                                : (order.status == OrderStatus.delivered
                                    ? 'PAID ON DELIVERY'
                                    : 'PENDING (COD)'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: order.paymentStatus == PaymentStatus.paid ||
                                      order.paymentMethod != PaymentMethod.cod ||
                                      order.status == OrderStatus.delivered
                                  ? const Color(0xFF1E9A4B)
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Total',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkDark,
                            ),
                          ),
                          Text(
                            AppFormatters.formatPrice(order.total),
                            style: const TextStyle(
                              fontSize: 16,
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

                // ── 7. Additional Order Actions ───────────────────────
                // Cancel Order Button (if cancellable)
                if (order.isCancellable) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _confirmCancelOrder(context, order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Return Order Button (if delivered)
                if (order.status == OrderStatus.delivered) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/orders/${order.id}/return'),
                      icon: const Icon(
                        Icons.assignment_return_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      label: const Text(
                        'Return Items',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Contact Support Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@marutistationery.com',
                        query: 'subject=Support for Order #MS$orderShortId',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open email client')),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.headset_mic_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Status Pill Badge ──────────────────────────────────────────────
  Widget _buildStatusPill(OrderStatus status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.delivered:
        bg = const Color(0xFFEAF8EF);
        text = const Color(0xFF1E9A4B);
        label = 'Delivered';
        icon = Icons.check_circle_rounded;
        break;
      case OrderStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        text = AppColors.error;
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case OrderStatus.returned:
        bg = const Color(0xFFEFF6FF);
        text = AppColors.royalBlue;
        label = 'Returned';
        icon = Icons.assignment_return_rounded;
        break;
      case OrderStatus.shipped:
        bg = const Color(0xFFEFF6FF);
        text = AppColors.royalBlue;
        label = 'Shipped';
        icon = Icons.local_shipping_rounded;
        break;
      case OrderStatus.packed:
        bg = const Color(0xFFFFF1EB);
        text = AppColors.primary;
        label = 'Packed';
        icon = Icons.inventory_2_rounded;
        break;
      case OrderStatus.confirmed:
        bg = const Color(0xFFFFF1EB);
        text = AppColors.primary;
        label = 'Confirmed';
        icon = Icons.check_rounded;
        break;
      case OrderStatus.placed:
        bg = const Color(0xFFFFF1EB);
        text = AppColors.primary;
        label = 'Order Placed';
        icon = Icons.receipt_long_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline Step Row ──────────────────────────────────────────────
  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    bool isCancelled = false,
    required bool isLast,
  }) {
    Color indicatorColor;
    Widget indicatorChild;

    if (isCancelled) {
      indicatorColor = AppColors.error;
      indicatorChild = const Icon(Icons.close_rounded, size: 14, color: Colors.white);
    } else if (isCompleted) {
      indicatorColor = AppColors.royalBlue;
      indicatorChild = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
    } else if (isCurrent) {
      indicatorColor = AppColors.primary;
      indicatorChild = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      indicatorColor = const Color(0xFFCBD5E1);
      indicatorChild = const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Circle & Connecting Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  border: isCompleted || isCurrent || isCancelled
                      ? null
                      : Border.all(color: const Color(0xFF94A3B8), width: 1.5),
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? AppColors.royalBlue
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isCompleted || isCurrent
                          ? AppColors.inkDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
