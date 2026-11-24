import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class AdminScaffold extends StatelessWidget {
  final Widget child;

  const AdminScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/admin/products')) return 1;
    if (location.startsWith('/admin/orders')) return 2;
    if (location.startsWith('/admin/coupons')) return 3;
    if (location.startsWith('/admin/settings')) return 4;
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/products');
        break;
      case 2:
        context.go('/admin/orders');
        break;
      case 3:
        context.go('/admin/coupons');
        break;
      case 4:
        context.go('/admin/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Products',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.local_offer_outlined,
                  activeIcon: Icons.local_offer_rounded,
                  label: 'Coupons',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: selectedIndex == 4,
                  onTap: () => _onItemTapped(4, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 23,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
