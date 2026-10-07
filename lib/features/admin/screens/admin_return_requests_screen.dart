import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/shared/widgets/app_button.dart';
import 'package:maruti_stationery/core/utils/formatters.dart';
import '../../../models/return_request_model.dart';
import '../../../services/return_request_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';

class AdminReturnRequestsScreen extends StatefulWidget {
  const AdminReturnRequestsScreen({super.key});

  @override
  State<AdminReturnRequestsScreen> createState() => _AdminReturnRequestsScreenState();
}

class _AdminReturnRequestsScreenState extends State<AdminReturnRequestsScreen> {
  final ReturnRequestService _returnService = ReturnRequestService();

  void _showActionDialog(ReturnRequestModel request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Return Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.check_circle, color: context.colors.success),
                title: const Text('Accept Return & Issue Points'),
                onTap: () {
                  context.pop();
                  _promptForPoints(request);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_rounded, color: Colors.blue),
                title: const Text('Accept Return & Refund Money'),
                onTap: () {
                  context.pop();
                  _updateStatus(request, ReturnStatus.accepted, RefundMethod.money);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: context.colors.error),
                title: const Text('Reject Return Request'),
                onTap: () {
                  context.pop();
                  _updateStatus(request, ReturnStatus.rejected, null);
                },
              ),
              ListTile(
                leading: Icon(Icons.done_all, color: context.colors.primary),
                title: const Text('Mark as Completed'),
                onTap: () {
                  context.pop();
                  _updateStatus(request, ReturnStatus.completed, request.refundMethod);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _promptForPoints(ReturnRequestModel request) {
    final TextEditingController pointsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Issue Points'),
          content: TextField(
            controller: pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Points to Award',
              hintText: 'e.g. 100',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final points = int.tryParse(pointsController.text.trim()) ?? 0;
                if (points > 0) {
                  Navigator.pop(context);
                  _updateStatus(request, ReturnStatus.accepted, RefundMethod.points, customPointsToAward: points);
                }
              },
              child: const Text('Accept & Issue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(ReturnRequestModel request, ReturnStatus status, RefundMethod? refundMethod, {int? customPointsToAward}) async {
    try {
      await _returnService.updateReturnRequestStatus(
        request.id, 
        status, 
        refundMethod,
        userId: request.userId,
      );

      if (status == ReturnStatus.accepted) {
        final batch = FirebaseFirestore.instance.batch();
        
        // Mark order as returned
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(request.orderId);
        batch.update(orderRef, {'status': 'returned', 'updatedAt': FieldValue.serverTimestamp()});
        
        // Increment stock
        for (final item in request.items) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
          batch.set(productRef, {'stock': FieldValue.increment(item.qty)}, SetOptions(merge: true));
        }
        
        await batch.commit();
      }

      // If points were selected, increment user points
      if (status == ReturnStatus.accepted && refundMethod == RefundMethod.points && customPointsToAward != null) {
        await FirebaseFirestore.instance.collection('users').doc(request.userId).update({
          'loyaltyPoints': FieldValue.increment(customPointsToAward),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Return Requests'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<ReturnRequestModel>>(
        stream: _returnService.getAllReturnRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No return requests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                color: context.colors.surface,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${req.orderId.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.status == ReturnStatus.pending ? Colors.orange.withOpacity(0.2)
                                  : req.status == ReturnStatus.accepted ? Colors.blue.withOpacity(0.2)
                                  : req.status == ReturnStatus.rejected ? Colors.red.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: req.status == ReturnStatus.pending ? Colors.orange
                                  : req.status == ReturnStatus.accepted ? Colors.blue
                                  : req.status == ReturnStatus.rejected ? Colors.red
                                  : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Requested: ${DateFormat('MMM dd, yyyy - hh:mm a').format(req.createdAt)}', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      const SizedBox(height: 12),
                      Text('Reason: ${req.reason}', style: TextStyle(color: context.colors.textPrimary)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      ...req.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('${item.qty}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(AppFormatters.formatPrice(item.price * item.qty)),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Refund:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(AppFormatters.formatPrice(req.totalRefundAmount), style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary)),
                        ],
                      ),
                      if (req.refundMethod != null) ...[
                        const SizedBox(height: 8),
                        Text('Refund Method: ${req.refundMethod!.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.success)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: 'Update Status',
                          onPressed: () => _showActionDialog(req),
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
