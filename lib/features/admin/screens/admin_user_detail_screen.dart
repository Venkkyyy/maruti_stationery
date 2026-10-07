import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../models/order_model.dart';
import '../../../models/cart_item_model.dart';
import '../../../services/admin_fcm_service.dart';
import '../../../core/utils/formatters.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final UserModel? user;
  
  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    this.user,
  });

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _isSendingReminder = false;
  
  Future<void> _sendReminder(String title, String body) async {
    setState(() => _isSendingReminder = true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
      for (final token in tokens) {
        await AdminFCMService.sendNotification(
          targetTokenOrTopic: token,
          title: title,
          body: body,
          data: {'type': 'marketing'},
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder sent to ${widget.user?.name ?? 'Customer'}!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reminder: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(widget.user?.name ?? 'Customer Details'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 24),
              _buildCartSection(),
              const SizedBox(height: 24),
              _buildOrdersSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person, color: context.colors.primary),
              title: Text(widget.user?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.user?.phone ?? ''),
            ),
            if (widget.user?.email != null)
              ListTile(
                leading: Icon(Icons.email, color: context.colors.textSecondary),
                title: Text(widget.user!.email!),
              ),
            ListTile(
              leading: Icon(Icons.stars, color: Colors.amber),
              title: Text('${widget.user?.loyaltyPoints ?? 0} Loyalty Points'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Current Cart Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primaryLight,
                foregroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _isSendingReminder ? null : () => _sendReminder(
                '🔥 Items in your cart are selling fast!',
                'Don\'t miss out! Complete your checkout before they run out of stock.',
              ),
              icon: _isSendingReminder 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.notification_add_rounded, size: 16),
              label: const Text('Send Reminder'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('carts').doc(widget.userId).collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading cart: ${snapshot.error}');
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Card(
                color: context.colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('Cart is empty', style: TextStyle(color: context.colors.textSecondary))),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final item = CartItemModel.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
                return Card(
                  color: context.colors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                    subtitle: Text('Qty: ${item.qty}  •  ${AppFormatters.formatPrice(item.price)}'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading orders: ${snapshot.error}');
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Card(
                color: context.colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('No orders yet', style: TextStyle(color: context.colors.textSecondary))),
                ),
              );
            }
            
            final orders = docs.map((d) => OrderModel.fromFirestore(d)).toList();
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  color: context.colors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text('Order #${order.id}', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                    subtitle: Text('${order.status.name.toUpperCase()} • ${AppFormatters.formatPrice(order.total)}'),
                    children: order.items.map((item) {
                      return ListTile(
                        title: Text(item.name, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('Qty: ${item.qty}'),
                        trailing: Text(AppFormatters.formatPrice(item.price)),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
