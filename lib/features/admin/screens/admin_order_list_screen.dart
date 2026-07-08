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
          
      // Write to notifications collection
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Order ${newStatus.name.toUpperCase()}',
        'body': 'Your order #${order.id.substring(0, 8).toUpperCase()} has been ${newStatus.name}.',
        'type': 'order',
        'userId': order.userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          title: Row(
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
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
              const SizedBox(height: 4),
              Text(
                '${order.items.length} item(s)',
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '${order.address.name}\n${order.address.street}\n${order.address.city}, ${order.address.state} ${order.address.pincode}\nPhone: ${order.address.phone}',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.image, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width:40,height:40,color:Colors.grey.shade200)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${item.qty} x ${AppFormatters.formatPrice(item.price)}', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(AppFormatters.formatPrice(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text(AppFormatters.formatPrice(order.subtotal))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery:'), Text(AppFormatters.formatPrice(order.deliveryCharge))]),
                  if (order.discount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Discount:'), Text('-${AppFormatters.formatPrice(order.discount)}', style: const TextStyle(color: Colors.green))]),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)), Text(AppFormatters.formatPrice(order.total), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showStatusDialog(context),
                      child: const Text('Update Status'),
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
