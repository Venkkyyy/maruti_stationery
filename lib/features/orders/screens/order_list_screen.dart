import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/formatters.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Orders', 'Processing', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Maruti Stationery', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.search_rounded, color: context.colors.textPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: context.colors.surface,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                const SizedBox(height: 4),
                Text('Track, return, or buy items again.', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilter == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filters[index]),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedFilter = index);
                          },
                          backgroundColor: context.colors.surface,
                          selectedColor: context.colors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : context.colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? context.colors.primary : context.colors.border),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(authStateProvider).value;
                if (user == null) {
                  return const Center(child: Text('Please log in to see orders'));
                }
                final ordersAsync = ref.watch(watchUserOrdersProvider(user.uid));
                
                return ordersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(child: Text('No orders found'));
                    }
                    // Filter logic if needed
                    final filteredOrders = _selectedFilter == 0 
                      ? orders 
                      : orders.where((o) => o.statusLabel.toLowerCase() == _filters[_selectedFilter].toLowerCase()).toList();
                    
                    if (filteredOrders.isEmpty) {
                      return const Center(child: Text('No orders found for this status'));
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final firstItem = order.items.isNotEmpty ? order.items.first : null;
                        
                        return _buildOrderCard(
                          orderId: order.id,
                          date: order.createdAt.toString().split(' ')[0], // simple date formatting
                          status: order.statusLabel, // e.g. 'Processing'
                          title: firstItem?.name ?? 'Order Item',
                          details: 'Qty: ${firstItem?.qty ?? 0}',
                          price: AppFormatters.formatPrice(order.total),
                          buttonText: 'View Details',
                          buttonOutlined: true,
                          onTap: () => context.push('/orders/${order.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String date,
    required String status,
    required String title,
    required String details,
    required String price,
    required String buttonText,
    bool buttonOutlined = false,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    if (status == 'Shipped') {
      statusColor = context.colors.primary;
    } else if (status == 'Delivered') statusColor = context.colors.success;
    else statusColor = Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER #$orderId', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Placed on $date', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: context.colors.divider),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.surfaceGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_stories, color: context.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(details, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('+ 1 more item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.primary.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: buttonOutlined
                ? OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textPrimary,
                      side: BorderSide(color: context.colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }
}

