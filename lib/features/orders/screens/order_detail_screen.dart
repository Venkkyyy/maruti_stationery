import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

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
        title: Text('Maruti Stationery', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.favorite_border, color: context.colors.textPrimary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: context.colors.surface,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Order #', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 24),
                  _buildTrackingStep(
                    title: 'Order Confirmed',
                    date: 'Mon, Oct 12 - 09:41 AM',
                    isActive: true,
                    isCompleted: true,
                    isFirst: true,
                  ),
                  _buildTrackingStep(
                    title: 'Shipped',
                    date: 'Wed, Oct 14 - 14:20 PM\nPackage has left our central logistics facility.',
                    isActive: true,
                    isCompleted: true,
                  ),
                  _buildTrackingStep(
                    title: 'Out for Delivery',
                    date: 'Wed, Oct 14 - Est. 14:00 - 18:00',
                    isActive: true,
                    isCompleted: false,
                  ),
                  _buildTrackingStep(
                    title: 'Delivered',
                    date: '',
                    isActive: false,
                    isCompleted: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ITEMS IN THIS SHIPMENT', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.colors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Icon(Icons.edit_rounded, color: context.colors.primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Classic Mahogany Fountain Pen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Color: Mahogany - Nib: Medium', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('?2,450.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                                const SizedBox(width: 6),
                                Text('?2,950.00', style: TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: context.colors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.help_outline, size: 16, color: context.colors.textSecondary),
                      label: Text('Help Center', style: TextStyle(color: context.colors.textSecondary)),
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

  Widget _buildTrackingStep({
    required String title,
    required String date,
    required bool isActive,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success : (isActive ? AppColors.primary : AppColors.surfaceGrey),
                border: isCompleted || isActive ? null : Border.all(color: AppColors.border, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : (isActive ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

