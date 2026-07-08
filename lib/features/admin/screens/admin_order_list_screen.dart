import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../core/utils/formatters.dart';

class AdminOrderListScreen extends StatelessWidget {
  const AdminOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: context.colors.surface,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _AdminOrderTile(order: order);
            },
          );
        },
      ),
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  final OrderModel order;

  const _AdminOrderTile({required this.order});

  Future<void> _updateStatus(BuildContext context, OrderStatus newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'status': newStatus.name, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showStatusDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: OrderStatus.values.map((status) {
              return ListTile(
                title: Text(
                  status.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: order.status == status ? FontWeight.bold : FontWeight.normal,
                    color: order.status == status ? context.colors.primary : context.colors.textPrimary,
                  ),
                ),
                trailing: order.status == status ? Icon(Icons.check, color: context.colors.primary) : null,
                onTap: () {
                  Navigator.pop(context);
                  if (order.status != status) {
                    _updateStatus(context, status);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = order.status == OrderStatus.placed || order.status == OrderStatus.confirmed;
    final bool isDelivered = order.status == OrderStatus.delivered;
    final bool isCancelled = order.status == OrderStatus.cancelled;

    Color statusColor = context.colors.primary;
    if (isProcessing) statusColor = Colors.orange;
    if (isDelivered) statusColor = Colors.green;
    if (isCancelled) statusColor = context.colors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                order.address.name,
                style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
              ),
              Text(
                ' • ${AppFormatters.formatPrice(order.total)}',
                style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${order.items.length} item(s)',
                  style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _showStatusDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Update Status',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.colors.textPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
