import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class AdminFinancialReportsScreen extends StatefulWidget {
  const AdminFinancialReportsScreen({super.key});

  @override
  State<AdminFinancialReportsScreen> createState() => _AdminFinancialReportsScreenState();
}

class _AdminFinancialReportsScreenState extends State<AdminFinancialReportsScreen> {
  String _selectedPeriod = 'This Month'; // 'Today', 'This Week', 'This Month', 'This Year', 'All Time'

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek) || (date.year == startOfWeek.year && date.month == startOfWeek.month && date.day == startOfWeek.day);
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      case 'This Year':
        return date.year == now.year;
      case 'All Time':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Financial & Tax Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reporting Period:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.royalBlue),
                  items: ['Today', 'This Week', 'This Month', 'This Year', 'All Time'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.royalBlue)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPeriod = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Streams for Orders and Purchases
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, ordersSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('purchases').snapshots(),
                builder: (context, purchasesSnap) {
                  if (ordersSnap.connectionState == ConnectionState.waiting || purchasesSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                  }

                  // 1. Calculate Gross Online Sales
                  int grossSalesPaise = 0;
                  int deliveredOrdersCount = 0;
                  final orderDocs = ordersSnap.data?.docs ?? [];
                  for (final d in orderDocs) {
                    final data = d.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final status = data['status'] as String? ?? '';

                    if (_matchesPeriod(createdAt) && (status == 'delivered' || status == 'shipped' || status == 'packed' || status == 'confirmed')) {
                      grossSalesPaise += (data['total'] as num?)?.toInt() ?? 0;
                      if (status == 'delivered') deliveredOrdersCount++;
                    }
                  }

                  // 2. Calculate Total Inward Purchases
                  int purchaseCostPaise = 0;
                  final purchaseDocs = purchasesSnap.data?.docs ?? [];
                  for (final d in purchaseDocs) {
                    final data = d.data() as Map<String, dynamic>;
                    final pDate = (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                    if (_matchesPeriod(pDate)) {
                      purchaseCostPaise += (data['totalCost'] as num?)?.toInt() ?? 0;
                    }
                  }

                  final grossProfitPaise = grossSalesPaise - purchaseCostPaise;
                  final double estimatedGSTPaise = grossSalesPaise * 0.18; // 18% standard stationery GST estimation
                  final aovPaise = deliveredOrdersCount > 0 ? (grossSalesPaise / deliveredOrdersCount).round() : 0;

                  return Column(
                    children: [
                      // Revenue & Profit Hero Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF173A9B), Color(0xFF0D256B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x30173A9B), blurRadius: 16, offset: Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GROSS SALES REVENUE', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                            const SizedBox(height: 6),
                            Text(
                              AppFormatters.formatPrice(grossSalesPaise),
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Inward Stock Cost', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(AppFormatters.formatPrice(purchaseCostPaise), style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Est. Gross Margin', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppFormatters.formatPrice(grossProfitPaise > 0 ? grossProfitPaise : 0),
                                      style: GoogleFonts.poppins(color: const Color(0xFF4ADE80), fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Metrics Breakdown
                      _buildFinancialRow(
                        title: 'Estimated Output GST (18%)',
                        subtitle: 'Calculated on sales invoice value',
                        value: AppFormatters.formatPrice(estimatedGSTPaise.round()),
                        icon: Icons.account_balance_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildFinancialRow(
                        title: 'Average Order Value (AOV)',
                        subtitle: 'Average revenue per delivered checkout',
                        value: AppFormatters.formatPrice(aovPaise),
                        icon: Icons.shopping_basket_rounded,
                        color: AppColors.royalBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildFinancialRow(
                        title: 'Delivered Orders Count',
                        subtitle: 'Successfully completed orders in this period',
                        value: '$deliveredOrdersCount orders',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyText)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyText)),
        ],
      ),
    );
  }
}

