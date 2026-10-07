import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/shared/widgets/app_button.dart';
import 'package:maruti_stationery/shared/widgets/app_text_field.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/return_request_model.dart';
import '../../../services/return_request_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ReturnOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReturnOrderScreen> createState() => _ReturnOrderScreenState();
}

class _ReturnOrderScreenState extends ConsumerState<ReturnOrderScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  final Map<String, int> _selectedReturnQtys = {}; // productId -> qty to return
  final Map<String, bool> _returnableCache = {}; // productId -> isReturnable
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      if (orderDoc.exists) {
        _order = OrderModel.fromFirestore(orderDoc);
        
        // Fetch product isReturnable status
        for (var item in _order!.items) {
          final pDoc = await FirebaseFirestore.instance.collection('products').doc(item.productId).get();
          if (pDoc.exists) {
            final p = ProductModel.fromFirestore(pDoc);
            _returnableCache[item.productId] = p.isReturnable;
          } else {
            _returnableCache[item.productId] = false;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading return data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitReturn() async {
    if (_selectedReturnQtys.isEmpty || _selectedReturnQtys.values.every((v) => v == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one item to return.')));
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason for return.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<ReturnItem> returnItems = [];
      int totalRefund = 0;

      for (var entry in _selectedReturnQtys.entries) {
        if (entry.value > 0) {
          final orderItem = _order!.items.firstWhere((i) => i.productId == entry.key);
          returnItems.add(ReturnItem(
            productId: orderItem.productId,
            name: orderItem.name,
            image: orderItem.image,
            qty: entry.value,
            price: orderItem.price,
          ));
          totalRefund += orderItem.price * entry.value;
        }
      }

      final request = ReturnRequestModel(
        id: '', // Firestore will auto-generate
        orderId: _order!.id,
        userId: _order!.userId,
        items: returnItems,
        reason: _reasonController.text.trim(),
        status: ReturnStatus.pending,
        totalRefundAmount: totalRefund,
        createdAt: DateTime.now(),
      );

      await ReturnRequestService().createReturnRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return request submitted successfully.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(backgroundColor: context.colors.surface, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(backgroundColor: context.colors.surface, elevation: 0),
        body: const Center(child: Text('Order not found.')),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Return Items', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Select items to return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textPrimary)),
                const SizedBox(height: 16),
                ..._order!.items.map((item) {
                  final isReturnable = _returnableCache[item.productId] ?? false;
                  final currentQty = _selectedReturnQtys[item.productId] ?? 0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.image.isNotEmpty
                              ? Image.network(item.image, width: 60, height: 60, fit: BoxFit.cover)
                              : Container(width: 60, height: 60, color: context.colors.surfaceGrey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (!isReturnable)
                                const Text('Not Returnable', style: TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isReturnable)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: currentQty > 0 
                                  ? () => setState(() => _selectedReturnQtys[item.productId] = currentQty - 1)
                                  : null,
                              ),
                              Text('$currentQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: currentQty < item.qty
                                  ? () => setState(() => _selectedReturnQtys[item.productId] = currentQty + 1)
                                  : null,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _reasonController,
                  label: 'Reason for return',
                  maxLines: 4,
                  hint: 'Please explain why you are returning these items...',
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                text: 'Submit Return Request',
                onPressed: _isSubmitting ? null : _submitReturn,
                isLoading: _isSubmitting,
                variant: AppButtonVariant.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
