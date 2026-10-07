import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/admin_fcm_service.dart';
import '../../../services/invoice_service.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  String _searchQuery = '';
  final List<String> _tabs = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: const Text('Manage Orders'),
          backgroundColor: context.colors.surface,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            isScrollable: true,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primary,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search orders by ID...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: context.colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _tabs.map((tab) => _buildOrderList(tab)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String tabStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        var orders = snapshot.data!.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        
        // Sort locally to handle pending server timestamps
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (tabStatus != 'All') {
          orders = orders.where((order) {
            if (tabStatus == 'Pending') return order.status == OrderStatus.placed || order.status == OrderStatus.confirmed;
            if (tabStatus == 'Processing') return order.status == OrderStatus.packed;
            if (tabStatus == 'Shipped') return order.status == OrderStatus.shipped;
            if (tabStatus == 'Delivered') return order.status == OrderStatus.delivered;
            if (tabStatus == 'Cancelled') return order.status == OrderStatus.cancelled || order.status == OrderStatus.returned;
            return true;
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          orders = orders.where((order) {
            return order.id.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (orders.isEmpty) {
          return Center(child: Text('No $tabStatus orders found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _AdminOrderTile(
              key: ValueKey('${order.id}_${order.status.name}'),
              order: order,
            );
          },
        );
      },
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  final OrderModel order;

  const _AdminOrderTile({super.key, required this.order});

  Future<void> _updateStatus(BuildContext context, OrderStatus newStatus) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(order.id);
      
      batch.update(orderRef, {'status': newStatus.name, 'updatedAt': FieldValue.serverTimestamp()});

      // Handle stock adjustments
      bool isNowRestocked = newStatus == OrderStatus.cancelled || newStatus == OrderStatus.returned;
      bool wasRestocked = order.status == OrderStatus.cancelled || order.status == OrderStatus.returned;
      
      if (isNowRestocked && !wasRestocked) {
        // Increment stock
        for (final item in order.items) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
          batch.set(productRef, {'stock': FieldValue.increment(item.qty)}, SetOptions(merge: true));
        }
      } else if (wasRestocked && !isNowRestocked) {
        // Decrement stock
        for (final item in order.items) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
          batch.set(productRef, {'stock': FieldValue.increment(-item.qty)}, SetOptions(merge: true));
        }
      }

      await batch.commit();

      // Detailed notification text based on status
      final productNames = order.items.map((i) => '${i.qty}x ${i.name}').take(2).join(', ');
      final moreCount = order.items.length > 2 ? ' and ${order.items.length - 2} more' : '';
      final itemsStr = '$productNames$moreCount';

      String notifTitle = 'Order Update';
      String notifBody = 'Your order #${order.id.toUpperCase()} has been updated.';
      
      switch (newStatus) {
        case OrderStatus.confirmed:
          notifTitle = 'Order Confirmed!';
          notifBody = 'Your order containing $itemsStr is confirmed and being prepared.';
          break;
        case OrderStatus.packed:
          notifTitle = 'Order Packed';
          notifBody = 'Your order containing $itemsStr is packed and ready for shipping.';
          break;
        case OrderStatus.shipped:
          notifTitle = 'Order Shipped!';
          notifBody = 'Great news! Your order containing $itemsStr is on the way to you.';
          break;
        case OrderStatus.delivered:
          notifTitle = 'Order Delivered';
          notifBody = 'Your order containing $itemsStr has been delivered successfully. Thank you for shopping with us!';
          break;
        case OrderStatus.cancelled:
          notifTitle = 'Order Cancelled';
          notifBody = 'Your order containing $itemsStr has been cancelled.';
          break;
        default:
          notifTitle = 'Order ${newStatus.name.toUpperCase()}';
          notifBody = 'Your order #${order.id.toUpperCase()} has been ${newStatus.name}.';
      }

      // Write to notifications collection
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': notifTitle,
        'body': notifBody,
        'type': 'order',
        'userId': order.userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Option B Workaround: Send push notification to customer
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(order.userId).get();
        final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
        if (tokens.isNotEmpty) {
          for (final token in tokens) {
            await AdminFCMService.sendNotification(
              targetTokenOrTopic: token,
              title: notifTitle,
              body: notifBody,
              data: {
                'type': 'order',
                'orderId': order.id,
              },
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to send FCM to customer: $e');
      }
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
      builder: (sheetContext) => SafeArea(
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
                    color: _getStatusColor(context, status),
                  ),
                ),
                trailing: order.status == status ? Icon(Icons.check, color: _getStatusColor(context, status)) : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (order.status != status) {
                    if (status == OrderStatus.cancelled) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: context.colors.surface,
                          title: Text('Cancel Order', style: TextStyle(color: context.colors.textPrimary)),
                          content: Text('Are you sure you want to cancel this order? This will restore the stock.', style: TextStyle(color: context.colors.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text('No', style: TextStyle(color: context.colors.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text('Yes, Cancel', style: TextStyle(color: context.colors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }
                    if (context.mounted) {
                      _updateStatus(context, status);
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAssignPartnerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Assign Delivery Partner', style: TextStyle(color: context.colors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('isDeliveryPartner', isEqualTo: true).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Text('No delivery partners found.', style: TextStyle(color: context.colors.textSecondary));
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final name = (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
                  return ListTile(
                    title: Text(name, style: TextStyle(color: context.colors.textPrimary)),
                    trailing: order.deliveryPartnerId == doc.id ? Icon(Icons.check, color: context.colors.primary) : null,
                    onTap: () async {
                      Navigator.pop(c);
                      try {
                        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
                          'deliveryPartnerId': doc.id,
                          'status': OrderStatus.shipped.name, // Auto-update to shipped when assigned
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery partner assigned & status set to shipped')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, OrderStatus status) {
    if (status == OrderStatus.cancelled) return context.colors.error;
    if (status == OrderStatus.returned) return Colors.blue;
    if (status == OrderStatus.delivered) return Colors.green;
    if (status == OrderStatus.placed || status == OrderStatus.confirmed) return Colors.orange;
    return context.colors.primary;
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor(context, order.status);

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
                '#${order.id.toUpperCase()}',
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
                  if (order.deliveryPartnerId != null) ...[
                    const SizedBox(height: 12),
                    Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Assigned Partner ID: ${order.deliveryPartnerId}',
                      style: TextStyle(color: context.colors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (order.deliveredAt != null)
                      Text(
                        'Delivered At: ${AppFormatters.formatDate(order.deliveredAt!)}',
                        style: TextStyle(color: context.colors.success, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                  ],
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Payment Method:', style: TextStyle(fontSize: 13)), Text(order.paymentMethod.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Payment Status:', style: TextStyle(fontSize: 13)), Text(order.paymentStatus.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: order.paymentStatus == PaymentStatus.paid ? context.colors.success : Colors.orange))]),
                  const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => InvoiceService.generateAndPrintInvoice(order),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Invoice'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showStatusDialog(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Update Status'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAssignPartnerDialog(context),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: Text(order.deliveryPartnerId != null ? 'Re-assign Partner' : 'Assign Delivery Partner'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: order.deliveryPartnerId != null ? Colors.green : context.colors.primary,
                      ),
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
