import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/stock_log_model.dart';

class AdminStockHistoryScreen extends StatefulWidget {
  const AdminStockHistoryScreen({super.key});

  @override
  State<AdminStockHistoryScreen> createState() => _AdminStockHistoryScreenState();
}

class _AdminStockHistoryScreenState extends State<AdminStockHistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Inventory Movement Logs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stock changes by product or reason...',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stock_logs').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                var logs = docs.map((d) => StockLogModel.fromFirestore(d)).toList();

                if (_searchQuery.isNotEmpty) {
                  logs = logs.where((l) =>
                    l.productName.toLowerCase().contains(_searchQuery) ||
                    l.reason.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textHint.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'No inventory movements recorded yet.',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock updates via orders, purchases, and manual edits will appear here.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isPositive = log.quantityChange >= 0;
                    final changeColor = isPositive ? AppColors.success : AppColors.error;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: changeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                              color: changeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.productName,
                                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navyText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  log.reason,
                                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateFormat.format(log.timestamp),
                                  style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textHint),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}${log.quantityChange}',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: changeColor),
                              ),
                              Text(
                                'Stock: ${log.newStock}',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
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

