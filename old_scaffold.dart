import 'dart:ui';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import 'package:flutter/services.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).matchedLocation;

    final cartState = ref.watch(cartProvider);
    final bool isProductDetail = location.contains('/product/');
    final bool showCartBar = (cartState.value?.isNotEmpty ?? false) &&
        (location == '/home' ||
            location == '/categories' ||
            location == '/catalog' ||
            isProductDetail);

    int selectedIndex = 0;
    if (location.startsWith('/home')) {
      selectedIndex = 0;
    } else if (location.startsWith('/categories') ||
        location.startsWith('/catalog')) {
      selectedIndex = 1;
    } else if (location.startsWith('/search')) {
      selectedIndex = 2;
    } else if (location.startsWith('/cart')) {
      selectedIndex = 3;
    } else if (location.startsWith('/profile') ||
        location.startsWith('/orders')) {
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
              title: Text('Exit App',
                  style: TextStyle(color: context.colors.textPrimary)),
              content: Text('Are you sure you want to exit?',
                  style: TextStyle(color: context.colors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('No',
                      style:
                          TextStyle(color: context.colors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Yes',
                      style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold)),
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
        extendBody: true,
        body: Stack(
          children: [
            child,
            if (showCartBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 110,
                child: FloatingCartBar(
                  itemCount: cartState.value
                          ?.fold<int>(0, (sum, i) => sum + i.qty) ??
                      0,
                  totalPrice: cartState.value?.fold<int>(
                          0, (sum, i) => sum + (i.price * i.qty)) ??
                      0,
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: _WaterGlassBottomNav(
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Water Glass Bottom Nav with sliding ball indicator ─────────────────────

class _WaterGlassBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _WaterGlassBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_WaterGlassBottomNav> createState() => _WaterGlassBottomNavState();
}

class _WaterGlassBottomNavState extends State<_WaterGlassBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  int _prevIndex = 0;

  static const List<_NavData> _items = [
    _NavData(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavData(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Shop'),
    _NavData(Icons.search_rounded, Icons.search_rounded, 'Search'),
    _NavData(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Cart'),
    _NavData(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(_WaterGlassBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _slideAnimation = Tween<double>(
        begin: _prevIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ));
      _controller.forward(from: 0);
      _prevIndex = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    const itemCount = 5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            // Water-glass gradient effect
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.28),
                primary.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / itemCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Sliding indicator ball (water droplet / pill)
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, _) {
                      final x = _slideAnimation.value * itemWidth +
                          itemWidth / 2 -
                          24;
                      return Positioned(
                        left: x,
                        top: 8,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.9),
                                primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                              // Inner highlight (water glass shine)
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Nav items on top
                  Row(
                    children: List.generate(
                      itemCount,
                      (i) => _NavItemGlass(
                        index: i,
                        selectedIndex: widget.selectedIndex,
                        data: _items[i],
                        onTap: widget.onTap,
                        itemWidth: constraints.maxWidth / itemCount,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavData(this.icon, this.activeIcon, this.label);
}

class _NavItemGlass extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final _NavData data;
  final ValueChanged<int> onTap;
  final double itemWidth;

  const _NavItemGlass({
    required this.index,
    required this.selectedIndex,
    required this.data,
    required this.onTap,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        height: 68,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? data.activeIcon : data.icon,
              key: ValueKey(isSelected),
              size: 26,
              color: isSelected
                  ? Colors.white
                  : context.colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating Cart Bar ───────────────────────────────────────────────────────

class FloatingCartBar extends StatelessWidget {
  final int itemCount;
  final int totalPrice;

  const FloatingCartBar({
    super.key,
    required this.itemCount,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/cart'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary.withValues(alpha: 0.92),
                      context.colors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_bag_rounded,
                          color: context.colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'View cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$itemCount Item${itemCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
