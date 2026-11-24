import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).matchedLocation;
    final cartState = ref.watch(cartProvider);
    final cartItemCount = cartState.value?.fold<int>(0, (sum, i) => sum + i.qty) ?? 0;

    int selectedIndex = 0;
    if (location.startsWith('/home')) {
      selectedIndex = 0;
    } else if (location.startsWith('/categories') || location.startsWith('/catalog')) {
      selectedIndex = 1;
    } else if (location.startsWith('/cart')) {
      selectedIndex = 2;
    } else if (location.startsWith('/wishlist')) {
      selectedIndex = 3;
    } else if (location.startsWith('/profile') || location.startsWith('/orders')) {
      selectedIndex = 4;
    }

    void onTap(int index) {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/categories');
          break;
        case 2:
          context.go('/cart');
          break;
        case 3:
          context.go('/wishlist');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (location != '/home') {
          context.go('/home');
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Exit App',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              content: Text(
                'Are you sure you want to exit Maruti Stationery?',
                style: GoogleFonts.poppins(
                  color: context.colors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Exit',
                    style: GoogleFonts.poppins(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: child,
        bottomNavigationBar: _ReferenceBottomNavBar(
          selectedIndex: selectedIndex,
          cartItemCount: cartItemCount,
          onTap: onTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFERENCE BOTTOM NAVIGATION BAR (Matches Attached Design Exactly)
// ─────────────────────────────────────────────────────────────────────────────
class _ReferenceBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final int cartItemCount;
  final ValueChanged<int> onTap;

  const _ReferenceBottomNavBar({
    required this.selectedIndex,
    required this.cartItemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = context.colors.primary; // Vibrant Orange
    final inactiveColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0x12000000),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: selectedIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                isSelected: selectedIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart_rounded,
                label: 'Cart',
                isSelected: selectedIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                badgeCount: cartItemCount,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Wishlist',
                isSelected: selectedIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isSelected: selectedIndex == 4,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    int badgeCount = 0,
  }) {
    final effectiveIcon = isSelected && activeIcon != null ? activeIcon : icon;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  effectiveIcon,
                  size: 24,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
