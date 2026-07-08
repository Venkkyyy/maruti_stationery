import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/coupon_model.dart';
import '../../../services/admin_coupon_service.dart';
import '../../../core/utils/formatters.dart';

class AdminCouponsScreen extends StatelessWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Manage Coupons'),
        backgroundColor: context.colors.surface,
        automaticallyImplyLeading: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        onPressed: () => _showAddCouponDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coupons').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: context.colors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No coupons active.', style: TextStyle(color: context.colors.textSecondary)),
                ],
              ),
            );
          }

          final coupons = snapshot.data!.docs.map((doc) => CouponModel.fromFirestore(doc)).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _CouponTile(coupon: coupon);
            },
          );
        },
      ),
    );
  }

  void _showAddCouponDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _AddCouponForm(),
    );
  }
}

class _CouponTile extends StatelessWidget {
  final CouponModel coupon;
  const _CouponTile({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final bool isExpired = coupon.expiryDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  coupon.code,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.primary),
                ),
              ),
              Switch(
                value: coupon.isActive,
                activeColor: context.colors.primary,
                onChanged: (val) {
                  AdminCouponService().toggleCouponStatus(coupon.id, coupon.isActive);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${AppFormatters.formatPrice(coupon.discountAmount)} OFF',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Min. spend: ${AppFormatters.formatPrice(coupon.minOrderAmount)}',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expires: ${DateFormat('dd MMM yyyy').format(coupon.expiryDate)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? context.colors.error : context.colors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  AdminCouponService().deleteCoupon(coupon.id);
                },
                child: Icon(Icons.delete_outline, color: context.colors.error, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCouponForm extends StatefulWidget {
  const _AddCouponForm();

  @override
  State<_AddCouponForm> createState() => _AddCouponFormState();
}

class _AddCouponFormState extends State<_AddCouponForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _minOrderController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AdminCouponService().addCoupon(
        code: _codeController.text.trim(),
        discountAmount: (double.parse(_discountController.text.trim()) * 100).toInt(),
        minOrderAmount: (double.parse(_minOrderController.text.trim()) * 100).toInt(),
        expiryDate: _expiryDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add New Coupon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Coupon Code (e.g. SUMMER50)',
                filled: true,
                fillColor: context.colors.surfaceGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Discount Amount (₹)',
                filled: true,
                fillColor: context.colors.surfaceGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOrderController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Minimum Order Amount (₹)',
                filled: true,
                fillColor: context.colors.surfaceGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Expiry Date', style: TextStyle(color: context.colors.textSecondary)),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_expiryDate), style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Coupon', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
