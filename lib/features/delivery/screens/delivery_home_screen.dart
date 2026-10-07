import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/delivery_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';

class DeliveryHomeScreen extends ConsumerWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(deliveryOrdersStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: const Text('Delivery Partner Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authServiceProvider).signOut();
                context.go('/login');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Remaining'),
              Tab(text: 'Delivered'),
            ],
          ),
        ),
        body: ordersAsync.when(
          data: (allOrders) {
            final remainingOrders = allOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled && o.status != OrderStatus.returned).toList();
            final deliveredOrders = allOrders.where((o) => o.status == OrderStatus.delivered).toList();

            return TabBarView(
              children: [
                _buildOrderList(context, remainingOrders, 'No remaining orders.'),
                _buildOrderList(context, deliveredOrders, 'No delivered orders yet.'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Error loading orders: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<OrderModel> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: TextStyle(color: context.colors.textHint),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
              return InkWell(
                onTap: () => context.push('/order/${order.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.status.name == 'shipped' 
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: order.status.name == 'shipped' 
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: context.colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${order.address.name} (${order.address.phone})',
                            style: TextStyle(color: context.colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, size: 16, color: context.colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${order.items.length} Items: ${order.items.take(2).map((e) => e.name).join(', ')}${order.items.length > 2 ? ' ...' : ''}',
                              style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: context.colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${order.address.street}, ${order.address.city}, ${order.address.state} - ${order.address.pincode}',
                              style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.payment, size: 16, color: context.colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${order.paymentMethod.name.toUpperCase()} - ${AppFormatters.formatPrice(order.total)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }
}
