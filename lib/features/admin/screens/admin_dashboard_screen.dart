import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _revenueFilter = 'All Time';

  @override
  Widget build(BuildContext context) {
    final nowFormatted = DateFormat('EEE, dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.royalBlue,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20173A9B),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'M',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Maruti Stationery',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyText,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Store Admin Portal',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.royalBlue),
                const SizedBox(width: 6),
                Text(
                  nowFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Welcome Banner ──
          Text(
            'Welcome back, Admin 👋',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navyText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's your live stationery store summary & controls.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // ── Total Revenue Card ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', whereIn: ['placed', 'confirmed', 'packed', 'shipped', 'delivered'])
                .snapshots(),
            builder: (context, snapshot) {
              int totalRevenue = 0;
              if (snapshot.hasData) {
                final now = DateTime.now();
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;

                  bool include = false;
                  if (_revenueFilter == 'Today') {
                    include = createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
                  } else if (_revenueFilter == 'This Week') {
                    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                    include = createdAt.isAfter(startOfWeek) ||
                        (createdAt.year == startOfWeek.year && createdAt.month == startOfWeek.month && createdAt.day == startOfWeek.day);
                  } else if (_revenueFilter == 'This Month') {
                    include = createdAt.year == now.year && createdAt.month == now.month;
                  } else if (_revenueFilter == 'This Year') {
                    include = createdAt.year == now.year;
                  } else {
                    include = true;
                  }

                  if (include) {
                    totalRevenue += (data['total'] as num?)?.toInt() ?? 0;
                  }
                }
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.royalBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'TOTAL REVENUE',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButton<String>(
                            value: _revenueFilter,
                            items: ['Today', 'This Week', 'This Month', 'This Year', 'All Time']
                                .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navyText,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _revenueFilter = val);
                              }
                            },
                            underline: const SizedBox(),
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.royalBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppFormatters.formatPrice(totalRevenue),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navyText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revenue from confirmed & delivered stationery orders',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── 4 Store Metrics Grid ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, ordersSnap) {
              final allOrders = ordersSnap.hasData ? ordersSnap.data!.docs : [];
              final activeCount = allOrders.where((d) {
                final st = (d.data() as Map<String, dynamic>)['status'];
                return st != 'cancelled' && st != 'delivered';
              }).length;
              final deliveredCount = allOrders.where((d) {
                final st = (d.data() as Map<String, dynamic>)['status'];
                return st == 'delivered';
              }).length;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').where('stock', isLessThan: 10).snapshots(),
                builder: (context, productsSnap) {
                  final lowStockCount = productsSnap.hasData ? productsSnap.data!.docs.length : 0;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Active Orders',
                              value: activeCount.toString(),
                              icon: Icons.local_shipping_rounded,
                              iconColor: AppColors.royalBlue,
                              iconBg: AppColors.royalBlue.withValues(alpha: 0.12),
                              onTap: () => context.go('/admin/orders'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Low Stock Alerts',
                              value: lowStockCount.toString(),
                              icon: Icons.inventory_2_rounded,
                              iconColor: AppColors.primary,
                              iconBg: AppColors.primary.withValues(alpha: 0.12),
                              onTap: () => context.go('/admin/products'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Delivered',
                              value: deliveredCount.toString(),
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.success,
                              iconBg: AppColors.success.withValues(alpha: 0.12),
                              onTap: () => context.go('/admin/orders'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total Products',
                              value: (productsSnap.hasData ? 'View' : '...'),
                              icon: Icons.category_rounded,
                              iconColor: const Color(0xFF6366F1),
                              iconBg: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              onTap: () => context.go('/admin/products'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Quick Actions Grid ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Operations',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyText,
                ),
              ),
              Text(
                'Store Tools',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Modern 2-column action cards
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Bulk Excel Upload',
                  subtitle: 'Import .xlsx / .csv',
                  icon: Icons.table_view_rounded,
                  accentColor: AppColors.royalBlue,
                  isHighlighted: true,
                  onTap: () => context.push('/admin/products/bulk-upload'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Export Orders',
                  subtitle: 'Download Excel report',
                  icon: Icons.file_download_rounded,
                  accentColor: AppColors.primary,
                  onTap: () => context.push('/admin/orders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Add Product',
                  subtitle: 'Single new item',
                  icon: Icons.add_box_rounded,
                  accentColor: const Color(0xFF10B981),
                  onTap: () => context.push('/admin/products/add'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Manage Orders',
                  subtitle: 'Status & Invoices',
                  icon: Icons.receipt_long_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/admin/orders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Categories',
                  subtitle: 'Catalog structure',
                  icon: Icons.category_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  onTap: () => context.push('/admin/categories'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Coupons & Offers',
                  subtitle: 'Discount codes',
                  icon: Icons.local_offer_rounded,
                  accentColor: const Color(0xFFEC4899),
                  onTap: () => context.push('/admin/coupons'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Storefront CMS',
                  subtitle: 'SDUI, Sections & Versions',
                  icon: Icons.dashboard_customize_rounded,
                  accentColor: const Color(0xFF6366F1),
                  isHighlighted: true,
                  onTap: () => context.push('/admin/storefront'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Promotional Banners',
                  subtitle: 'Home screen carousels',
                  icon: Icons.view_carousel_rounded,
                  accentColor: const Color(0xFF06B6D4),
                  onTap: () => context.push('/admin/banners'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Video Ads',
                  subtitle: 'Reels & Impressions',
                  icon: Icons.smart_display_rounded,
                  accentColor: const Color(0xFFE11D48),
                  onTap: () => context.push('/admin/ads'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Brand Logos',
                  subtitle: 'Partners & Catalog',
                  icon: Icons.branding_watermark_rounded,
                  accentColor: const Color(0xFF0EA5E9),
                  onTap: () => context.push('/admin/brands'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Customers',
                  subtitle: 'Directory & Carts',
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFF3B82F6),
                  onTap: () => context.push('/admin/users'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Return Requests',
                  subtitle: 'Refunds & Restock',
                  icon: Icons.assignment_return_rounded,
                  accentColor: const Color(0xFFD97706),
                  onTap: () => context.push('/admin/returns'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Suppliers & Vendors',
                  subtitle: 'Manage wholesalers',
                  icon: Icons.store_rounded,
                  accentColor: const Color(0xFF0284C7),
                  onTap: () => context.push('/admin/suppliers'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Purchase Inward',
                  subtitle: 'Stock inward & POs',
                  icon: Icons.add_shopping_cart_rounded,
                  accentColor: const Color(0xFF059669),
                  onTap: () => context.push('/admin/purchases'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Financial & Tax',
                  subtitle: 'Revenue, GST & Profit',
                  icon: Icons.account_balance_rounded,
                  accentColor: const Color(0xFF4F46E5),
                  onTap: () => context.push('/admin/financial-reports'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Inventory Logs',
                  subtitle: 'Stock movements',
                  icon: Icons.history_rounded,
                  accentColor: const Color(0xFFEA580C),
                  onTap: () => context.push('/admin/stock-history'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Staff & Roles',
                  subtitle: 'Team & Permissions',
                  icon: Icons.badge_rounded,
                  accentColor: const Color(0xFF7C3AED),
                  onTap: () => context.push('/admin/staff'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Security Logs',
                  subtitle: 'Admin action audit',
                  icon: Icons.security_rounded,
                  accentColor: const Color(0xFFDC2626),
                  onTap: () => context.push('/admin/audit-logs'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Visual Order Fulfillment Analytics ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              final orders = snapshot.data?.docs ?? [];
              final total = orders.length;

              int delivered = 0;
              int processing = 0;
              int cancelled = 0;

              for (final d in orders) {
                final st = (d.data() as Map<String, dynamic>)['status'] ?? '';
                if (st == 'delivered') {
                  delivered++;
                } else if (st == 'cancelled' || st == 'returned') {
                  cancelled++;
                } else {
                  processing++;
                }
              }

              final delRatio = total > 0 ? (delivered / total) : 0.0;
              final procRatio = total > 0 ? (processing / total) : 0.0;
              final canRatio = total > 0 ? (cancelled / total) : 0.0;

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Fulfillment Health', style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.navyText)),
                        Text('$total Total Orders', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Segmented colored bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            if (delivered > 0)
                              Expanded(flex: (delRatio * 100).toInt(), child: Container(color: AppColors.success)),
                            if (processing > 0)
                              Expanded(flex: (procRatio * 100).toInt(), child: Container(color: AppColors.primary)),
                            if (cancelled > 0)
                              Expanded(flex: (canRatio * 100).toInt(), child: Container(color: AppColors.error)),
                            if (total == 0)
                              Expanded(child: Container(color: AppColors.surfaceWarm)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFulfillmentBadge('Delivered', '$delivered (${(delRatio * 100).toStringAsFixed(0)}%)', AppColors.success),
                        _buildFulfillmentBadge('Processing', '$processing (${(procRatio * 100).toStringAsFixed(0)}%)', AppColors.primary),
                        _buildFulfillmentBadge('Cancelled', '$cancelled (${(canRatio * 100).toStringAsFixed(0)}%)', AppColors.error),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Recent Orders ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyText,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/orders'),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'No recent orders found.',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  String itemsString = '';
                  if (data['items'] != null) {
                    final itemsList = data['items'] as List<dynamic>;
                    if (itemsList.isNotEmpty) {
                      itemsString = '${itemsList[0]['qty']}x ${itemsList[0]['name']}';
                      if (itemsList.length > 1) {
                        itemsString += ' + ${itemsList.length - 1} more';
                      }
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecentOrderTile(
                      context,
                      orderId: doc.id.toUpperCase(),
                      customer: data['address']?['name'] ?? 'Customer',
                      amount: (data['total'] as num?)?.toInt() ?? 0,
                      items: itemsString,
                      status: data['status'] ?? 'Processing',
                      fullId: doc.id,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textHint),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navyText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? accentColor.withValues(alpha: 0.4) : AppColors.border,
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted ? accentColor.withValues(alpha: 0.1) : const Color(0x0A000000),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
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

  Widget _buildRecentOrderTile(
    BuildContext context, {
    required String orderId,
    required String customer,
    required int amount,
    required String items,
    required String status,
    required String fullId,
  }) {
    final statusLower = status.toLowerCase();
    Color statusColor = AppColors.royalBlue;
    if (statusLower == 'delivered') {
      statusColor = AppColors.success;
    } else if (statusLower == 'cancelled' || statusLower == 'returned') {
      statusColor = AppColors.error;
    } else if (statusLower == 'placed' || statusLower == 'confirmed') {
      statusColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$orderId',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: AppColors.navyText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                customer,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              Text(
                ' • ${AppFormatters.formatPrice(amount)}',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              items,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFulfillmentBadge(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textSecondary)),
            Text(value, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.navyText)),
          ],
        ),
      ],
    );
  }
}
