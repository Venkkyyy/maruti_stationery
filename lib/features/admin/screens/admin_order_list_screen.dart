import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/admin_fcm_service.dart';
import '../../../services/fcm_service.dart';
import '../../../services/gmail_automation_service.dart';
import '../../../services/invoice_service.dart';
import '../../../services/admin_excel_service.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  final AdminExcelService _excelService = AdminExcelService();

  String _searchQuery = '';
  String _selectedDateFilter = 'All Time'; // 'All Time', 'Today', 'Yesterday', 'This Week', 'This Month', 'Custom'
  DateTimeRange? _customDateRange;
  bool _isExporting = false;

  final List<String> _tabs = [
    'All',
    'Delivered',
    'Not Delivered',
    'Processing',
    'Shipped',
    'Cancelled',
  ];

  Future<void> _handleDateFilterSelect(String filter) async {
    if (filter == 'Custom') {
      final initialRange = _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          );
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: initialRange,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.royalBlue,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.navyText,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          _customDateRange = picked;
          _selectedDateFilter = 'Custom';
        });
      }
    } else {
      setState(() {
        _selectedDateFilter = filter;
        _customDateRange = null;
      });
    }
  }

  bool _matchesDateFilter(DateTime orderDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    switch (_selectedDateFilter) {
      case 'Today':
        return orderDate.isAfter(todayStart) && orderDate.isBefore(todayEnd);
      case 'Yesterday':
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        return orderDate.isAfter(yesterdayStart) && orderDate.isBefore(todayStart);
      case 'This Week':
        final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
        return orderDate.isAfter(startOfWeek);
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return orderDate.isAfter(startOfMonth);
      case 'Custom':
        if (_customDateRange != null) {
          final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
          final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
          return orderDate.isAfter(start.subtract(const Duration(seconds: 1))) && orderDate.isBefore(end.add(const Duration(seconds: 1)));
        }
        return true;
      case 'All Time':
      default:
        return true;
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> allOrders, String tabStatus) {
    return allOrders.where((order) {
      // 1. Status Filter
      if (tabStatus == 'Delivered' && order.status != OrderStatus.delivered) return false;
      if (tabStatus == 'Not Delivered' && (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled || order.status == OrderStatus.returned)) return false;
      if (tabStatus == 'Processing' && (order.status != OrderStatus.placed && order.status != OrderStatus.confirmed && order.status != OrderStatus.packed)) return false;
      if (tabStatus == 'Shipped' && order.status != OrderStatus.shipped) return false;
      if (tabStatus == 'Cancelled' && (order.status != OrderStatus.cancelled && order.status != OrderStatus.returned)) return false;

      // 2. Date Filter
      if (!_matchesDateFilter(order.createdAt)) return false;

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = order.id.toLowerCase().contains(q);
        final matchesName = order.address.name.toLowerCase().contains(q);
        final matchesPhone = order.address.phone.contains(q);
        if (!matchesId && !matchesName && !matchesPhone) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _exportOrders(List<OrderModel> ordersToExport) async {
    if (ordersToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders found matching current filter to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      String filterLabel = _selectedDateFilter;
      if (_selectedDateFilter == 'Custom' && _customDateRange != null) {
        final dFormat = DateFormat('dd MMM');
        filterLabel = '${dFormat.format(_customDateRange!.start)} - ${dFormat.format(_customDateRange!.end)}';
      }

      await _excelService.exportOrdersToExcel(
        ordersToExport,
        filterLabel: filterLabel,
        startDate: _customDateRange?.start,
        endDate: _customDateRange?.end,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exported ${ordersToExport.length} orders to Excel!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Manage Orders',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 18),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: context.canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
                  onPressed: () => context.pop(),
                )
              : null,
          actions: [
            // Prominent Excel Export button in AppBar
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, snapshot) {
                final allOrders = snapshot.hasData
                    ? snapshot.data!.docs.map((doc) => OrderModel.fromFirestore(doc)).toList()
                    : <OrderModel>[];
                final currentFiltered = _filterOrders(allOrders, 'All');

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportOrders(currentFiltered),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.table_view_rounded, size: 18),
                    label: Text(
                      'Export Excel',
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOrders = snapshot.hasData
                ? snapshot.data!.docs.map((doc) => OrderModel.fromFirestore(doc)).toList()
                : <OrderModel>[];

            allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Column(
              children: [
                // Date Preset & Filter Toolbar
                _buildDateFilterToolbar(),

                // Search Bar & Stats Header
                _buildSearchAndStatsHeader(allOrders),

                // Order List Tabs View
                Expanded(
                  child: TabBarView(
                    children: _tabs.map((tab) {
                      final filtered = _filterOrders(allOrders, tab);
                      return _buildOrdersList(filtered, tab);
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateFilterToolbar() {
    final datePresets = ['All Time', 'Today', 'Yesterday', 'This Week', 'This Month', 'Custom'];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: datePresets.map((preset) {
            final isSelected = _selectedDateFilter == preset;
            String label = preset;
            if (preset == 'Custom' && _customDateRange != null) {
              final dFormat = DateFormat('dd/MM');
              label = '${dFormat.format(_customDateRange!.start)} - ${dFormat.format(_customDateRange!.end)}';
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => _handleDateFilterSelect(preset),
                backgroundColor: AppColors.surfaceWarm,
                selectedColor: AppColors.royalBlue,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.navyText,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.royalBlue : AppColors.border,
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchAndStatsHeader(List<OrderModel> allOrders) {
    final currentFiltered = _filterOrders(allOrders, 'All');
    final totalRevenue = currentFiltered.fold<int>(0, (sum, o) => sum + o.total);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID, Customer, Phone...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.royalBlue),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Showing ${currentFiltered.length} order(s)',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Total: ${AppFormatters.formatPrice(totalRevenue)}',
                style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.royalBlue, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String tabStatus) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 54, color: AppColors.textHint.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'No $tabStatus orders found',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing your date filter or search query.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _AdminOrderTile(
          key: ValueKey('${order.id}_${order.status.name}'),
          order: order,
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

      // Send push notification to customer
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

        // Trigger Gmail Delivered Automation (PIN is NOT included)
        if (newStatus == OrderStatus.delivered) {
          GmailAutomationService.sendOrderDeliveredEmail(
            orderId: order.id,
            userId: order.userId,
            deliveredAt: DateTime.now(),
            addressMap: {
              'street': order.address.street,
              'city': order.address.city,
              'state': order.address.state,
              'pincode': order.address.pincode,
              'name': order.address.name,
              'phone': order.address.phone,
            },
            itemCount: order.items.length,
          );
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: OrderStatus.values.map((status) {
              final color = _getStatusColor(status);
              return ListTile(
                title: Text(
                  status.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: order.status == status ? FontWeight.bold : FontWeight.normal,
                    color: color,
                  ),
                ),
                trailing: order.status == status ? Icon(Icons.check, color: color) : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (order.status != status) {
                    if (status == OrderStatus.cancelled) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          title: Text('Cancel Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText)),
                          content: Text('Are you sure you want to cancel this order? This will restore inventory stock.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text('No', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text('Yes, Cancel', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w700)),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Assign Delivery Partner', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText)),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('isDeliveryPartner', isEqualTo: true).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Text('No delivery partners found.', style: GoogleFonts.poppins(color: AppColors.textSecondary));

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final name = (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
                  return ListTile(
                    title: Text(name, style: GoogleFonts.poppins(color: AppColors.navyText)),
                    trailing: order.deliveryPartnerId == doc.id ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () async {
                      Navigator.pop(c);
                      try {
                        await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
                          'deliveryPartnerId': doc.id,
                          'status': OrderStatus.shipped.name,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        await FCMService.sendOrderStatusNotification(
                          orderId: order.id,
                          userId: order.userId,
                          status: 'shipped',
                          customTitle: 'Order Out for Delivery! 🚚',
                          customBody: 'Your order #${order.id.toUpperCase()} has been dispatched with delivery partner $name.',
                        );

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
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    if (status == OrderStatus.cancelled) return AppColors.error;
    if (status == OrderStatus.returned) return Colors.indigo;
    if (status == OrderStatus.delivered) return AppColors.success;
    if (status == OrderStatus.placed || status == OrderStatus.confirmed) return AppColors.primary;
    return AppColors.royalBlue;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.navyText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    order.address.name,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyText),
                  ),
                  Text(
                    ' • ${AppFormatters.formatPrice(order.total)}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${dateFormat.format(order.createdAt)}  •  ${order.items.length} item(s)',
                style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${order.address.name}\n${order.address.street}\n${order.address.city}, ${order.address.state} ${order.address.pincode}\nPhone: ${order.address.phone}',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                  ),
                  if (order.deliveryPartnerId != null) ...[
                    const SizedBox(height: 12),
                    Text('Delivery Partner', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Partner ID: ${order.deliveryPartnerId}',
                      style: GoogleFonts.poppins(color: AppColors.royalBlue, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    if (order.deliveredAt != null)
                      Text(
                        'Delivered At: ${AppFormatters.formatDate(order.deliveredAt!)}',
                        style: GoogleFonts.poppins(color: AppColors.success, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                  ],
                  const SizedBox(height: 14),
                  Text('Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.image,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 38,
                                  height: 38,
                                  color: AppColors.surfaceWarm,
                                  child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textHint),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.navyText)),
                                  Text('${item.qty} x ${AppFormatters.formatPrice(item.price)}', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(AppFormatters.formatPrice(item.total), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navyText)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  Text('Payment Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Subtotal', AppFormatters.formatPrice(order.subtotal)),
                  _buildSummaryRow('Delivery', AppFormatters.formatPrice(order.deliveryCharge)),
                  if (order.discount > 0)
                    _buildSummaryRow('Discount', '-${AppFormatters.formatPrice(order.discount)}', isDiscount: true),
                  if (order.pointsUsed > 0)
                    _buildSummaryRow('Loyalty Points Used', '${order.pointsUsed} pts'),
                  const Divider(color: AppColors.border),
                  _buildSummaryRow('Total Amount', AppFormatters.formatPrice(order.total), isBold: true),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Method', order.paymentMethod.name.toUpperCase()),
                  _buildSummaryRow(
                    'Payment Status',
                    order.paymentStatus.name.toUpperCase(),
                    customColor: order.paymentStatus == PaymentStatus.paid ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => InvoiceService.generateAndPrintInvoice(order),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: Text('Invoice', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.royalBlue,
                            side: const BorderSide(color: AppColors.royalBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showStatusDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: Text('Update Status', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAssignPartnerDialog(context),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: Text(
                        order.deliveryPartnerId != null ? 'Re-assign Delivery Partner' : 'Assign Delivery Partner',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: order.deliveryPartnerId != null ? AppColors.success : AppColors.royalBlue,
                        side: BorderSide(color: order.deliveryPartnerId != null ? AppColors.success : AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isDiscount = false, Color? customColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? AppColors.navyText : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: customColor ?? (isDiscount ? AppColors.success : (isBold ? AppColors.navyText : AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
