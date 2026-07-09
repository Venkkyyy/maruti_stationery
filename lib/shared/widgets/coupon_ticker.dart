import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import '../../providers/coupon_provider.dart';
import 'dart:async';

class CouponTicker extends ConsumerStatefulWidget {
  const CouponTicker({super.key});

  @override
  ConsumerState<CouponTicker> createState() => _CouponTickerState();
}

class _CouponTickerState extends ConsumerState<CouponTicker> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + 0.6);
        }
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.repeat();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(watchActiveCouponsProvider);

    return couponsAsync.when(
      data: (coupons) {
        if (coupons.isEmpty) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          height: 32,
          color: context.colors.primary,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              // Infinite loop by wrapping index
              final coupon = coupons[index % coupons.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer, size: 14, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'SAVE ₹${(coupon.discountAmount / 100).toStringAsFixed(0)} WITH CODE: ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
