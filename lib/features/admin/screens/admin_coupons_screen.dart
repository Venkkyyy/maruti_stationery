import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/coupon_model.dart';
import '../../../services/admin_coupon_service.dart';
import '../../../core/utils/formatters.dart';
import 'package:go_router/go_router.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  String _searchQuery = '';

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
        onPressed: () => context.push('/admin/coupons/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search coupons by code or name...',
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
            child: StreamBuilder<QuerySnapshot>(
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

                var coupons = snapshot.data!.docs.map((doc) => CouponModel.fromFirestore(doc)).toList();

                if (_searchQuery.isNotEmpty) {
                  coupons = coupons.where((c) => c.code.toLowerCase().contains(_searchQuery) || c.name.toLowerCase().contains(_searchQuery)).toList();
                }

                if (coupons.isEmpty) {
                  return const Center(child: Text('No matching coupons found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: coupons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return _CouponTile(coupon: coupon);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
              coupon.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              coupon.discountType == 'percentage'
                  ? '${coupon.discountAmount}% OFF'
                  : '₹${(coupon.discountAmount / 100).toStringAsFixed(0)} OFF',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.primary),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push('/admin/coupons/edit/${coupon.id}', extra: coupon);
                      },
                      child: Icon(Icons.edit_outlined, color: context.colors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
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
          ],
        ),
    );
  }
}


