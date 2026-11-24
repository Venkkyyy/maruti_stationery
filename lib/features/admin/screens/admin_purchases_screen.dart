import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/purchase_order_model.dart';
import 'admin_purchase_form_screen.dart';

class AdminPurchasesScreen extends StatefulWidget {
  const AdminPurchasesScreen({super.key});

  @override
  State<AdminPurchasesScreen> createState() => _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends State<AdminPurchasesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Purchase Orders & Inward',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'New Purchase',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPurchaseFormScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPurchaseFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text('Record Purchase', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search purchases by PO number, supplier, or invoice...',
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.royalBlue),
                filled: true,
                fillColor: AppColors.surfaceWarm,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Purchases List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('purchases').orderBy('purchaseDate', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                var orders = docs.map((d) => PurchaseOrderModel.fromFirestore(d)).toList();

                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((p) =>
                    p.orderNumber.toLowerCase().contains(_searchQuery) ||
                    p.supplierName.toLowerCase().contains(_searchQuery) ||
                    p.invoiceNumber.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textHint.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'No purchase orders recorded yet.',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + Record Purchase to track vendor stock inwards.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final po = orders[index];
                    return _PurchaseOrderCard(order: po);
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

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrderModel order;
  const _PurchaseOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.name.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Supplier: ${order.supplierName}',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.royalBlue),
          ),
          if (order.invoiceNumber.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Invoice: #${order.invoiceNumber}  •  ${dateFormat.format(order.purchaseDate)}',
              style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          ...order.items.take(3).map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${it.quantity}x ${it.productName}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppFormatters.formatPrice(it.totalCost),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyText),
                    ),
                  ],
                ),
              )),
          if (order.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${order.items.length - 3} more items',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Inward Amount:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyText)),
              Text(
                AppFormatters.formatPrice(order.totalCost),
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.royalBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

