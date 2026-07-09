import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import '../../../providers/order_provider.dart';
import '../../../models/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(watchOrderProvider(orderId));

    return Scaffold(
      backgroundColor: context.colors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Maruti Stationery', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: context.colors.surface,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.statusLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Placed on ${DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt)}', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                    ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 24),
                  if (order.status == OrderStatus.cancelled) ...[
                    _buildTrackingStep(
                      title: 'Order Placed',
                      date: DateFormat('EEE, MMM dd - hh:mm a').format(order.createdAt),
                      isActive: true,
                      isCompleted: true,
                      isFirst: true,
                    ),
                    _buildTrackingStep(
                      title: 'Cancelled',
                      date: 'Order has been cancelled.',
                      isActive: true,
                      isCompleted: true,
                      isLast: true,
                    ),
                  ] else ...[
                    _buildTrackingStep(
                      title: 'Order Placed',
                      date: DateFormat('EEE, MMM dd - hh:mm a').format(order.createdAt),
                      isActive: true,
                      isCompleted: true,
                      isFirst: true,
                    ),
                    _buildTrackingStep(
                      title: 'Confirmed',
                      date: order.status.index >= OrderStatus.confirmed.index ? 'Order confirmed by seller' : '',
                      isActive: order.status.index >= OrderStatus.confirmed.index,
                      isCompleted: order.status.index > OrderStatus.confirmed.index,
                    ),
                    _buildTrackingStep(
                      title: 'Packed',
                      date: order.status.index >= OrderStatus.packed.index ? 'Order is packed and ready to ship' : '',
                      isActive: order.status.index >= OrderStatus.packed.index,
                      isCompleted: order.status.index > OrderStatus.packed.index,
                    ),
                    _buildTrackingStep(
                      title: 'Shipped',
                      date: order.status.index >= OrderStatus.shipped.index ? 'Package has left our facility' : '',
                      isActive: order.status.index >= OrderStatus.shipped.index,
                      isCompleted: order.status.index > OrderStatus.shipped.index,
                    ),
                    _buildTrackingStep(
                      title: 'Delivered',
                      date: order.status.index >= OrderStatus.delivered.index ? 'Package delivered to the destination' : '',
                      isActive: order.status.index >= OrderStatus.delivered.index,
                      isCompleted: order.status.index >= OrderStatus.delivered.index,
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ITEMS IN THIS SHIPMENT', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.colors.textSecondary)),
                  const SizedBox(height: 16),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: context.colors.surfaceGrey,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.colors.border),
                              image: item.image.isNotEmpty ? DecorationImage(
                                image: NetworkImage(item.image),
                                fit: BoxFit.cover,
                              ) : null,
                            ),
                            child: item.image.isEmpty ? Icon(Icons.inventory_2_outlined, color: context.colors.primary, size: 30) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('Qty: ${item.qty} ${item.unit}', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                                const SizedBox(height: 8),
                                Text('₹${(item.price / 100).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/profile/help'),
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push('/profile/help'),
                      icon: Icon(Icons.help_outline, size: 16, color: context.colors.textSecondary),
                      label: Text('Help Center', style: TextStyle(color: context.colors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAYMENT DETAILS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.colors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Method', style: TextStyle(fontSize: 14)),
                      Text(order.paymentMethod.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 14)),
                      Text(
                        order.paymentStatus.name.toUpperCase(), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          color: order.paymentStatus == PaymentStatus.paid ? context.colors.success : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  ),
);
}

  Widget _buildTrackingStep({
    required String title,
    required String date,
    required bool isActive,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success : (isActive ? AppColors.primary : AppColors.surfaceGrey),
                border: isCompleted || isActive ? null : Border.all(color: AppColors.border, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : (isActive ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

