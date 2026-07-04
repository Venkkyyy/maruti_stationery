import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Orders', 'Processing', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Glacier', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.search_rounded, color: context.colors.textPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: context.colors.surface,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                const SizedBox(height: 4),
                Text('Track, return, or buy items again.', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilter == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filters[index]),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedFilter = index);
                          },
                          backgroundColor: context.colors.surface,
                          selectedColor: context.colors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : context.colors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? context.colors.primary : context.colors.border),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOrderCard(
                  orderId: 'OA-930AA',
                  date: 'Oct 24, 2023',
                  status: 'Shipped',
                  title: 'Premium Leather Notebook',
                  details: 'Size: A5 | Qty: 1',
                  price: '₹345',
                  buttonText: 'Track Order ->',
                  onTap: () => context.push('/orders/1'),
                ),
                const SizedBox(height: 16),
                _buildOrderCard(
                  orderId: 'OA-7712B',
                  date: 'Oct 12, 2023',
                  status: 'Delivered',
                  title: 'Executive Fountain Pen',
                  details: 'Nib: Medium | Qty: 1',
                  price: '₹129',
                  buttonText: 'Buy Again',
                  buttonOutlined: true,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildOrderCard(
                  orderId: 'OA-9001C',
                  date: 'Oct 28, 2023',
                  status: 'Processing',
                  title: 'Classic Artist Sketchbook',
                  details: 'Size: A4 | Qty: 2',
                  price: '₹178',
                  buttonText: 'View Details',
                  buttonOutlined: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String date,
    required String status,
    required String title,
    required String details,
    required String price,
    required String buttonText,
    bool buttonOutlined = false,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    if (status == 'Shipped') {
      statusColor = context.colors.primary;
    } else if (status == 'Delivered') statusColor = context.colors.success;
    else statusColor = Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER #$orderId', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Placed on $date', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: context.colors.divider),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.surfaceGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_stories, color: context.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(details, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('+ 1 more item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.primary.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: buttonOutlined
                ? OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textPrimary,
                      side: BorderSide(color: context.colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }
}

