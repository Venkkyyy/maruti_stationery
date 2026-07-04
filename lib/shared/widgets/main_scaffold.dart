import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.startsWith('/home')) {
      selectedIndex = 0;
    } else if (location.startsWith('/categories') || location.startsWith('/catalog')) {
      selectedIndex = 1;
    } else if (location.startsWith('/search')) {
      selectedIndex = 2;
    } else if (location.startsWith('/cart')) {
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
          context.go('/search');
          break;
        case 3:
          context.go('/cart');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        selectedIndex: selectedIndex,
        onTap: onTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                selectedIndex: selectedIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                selectedIndex: selectedIndex,
                icon: Icons.category_outlined,
                activeIcon: Icons.category_rounded,
                label: 'Categories',
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                selectedIndex: selectedIndex,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Explore',
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
                selectedIndex: selectedIndex,
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag_rounded,
                label: 'Cart',
                onTap: onTap,
              ),
              _NavItem(
                index: 4,
                selectedIndex: selectedIndex,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? Colors.white : context.colors.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}






