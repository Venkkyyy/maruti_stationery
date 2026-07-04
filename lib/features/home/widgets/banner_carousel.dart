import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';

/// Animated hero banner carousel for the home screen.
/// In production, banners come from Firestore. Here we use mock data.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_BannerData> _banners = const [
    _BannerData(
      label: 'SIGNATURE COLLECTION',
      title: 'Elevate Your Desk\nExperience',
      subtitle: 'Premium writing instruments',
      cta: 'Shop Now',
      route: '/catalog',
      bgStart: Color(0xFF0D1B2A),
      bgEnd: Color(0xFF1A2D42),
      accent: Color(0xFF1A73E8),
      icon: Icons.edit_rounded,
    ),
    _BannerData(
      label: 'NEW ARRIVALS',
      title: 'Parker Sonnet\nCollection 2026',
      subtitle: 'Fountain pens & rollerballs',
      cta: 'Explore',
      route: '/catalog',
      bgStart: Color(0xFF1A1A2E),
      bgEnd: Color(0xFF16213E),
      accent: Color(0xFF7C4DFF),
      icon: Icons.auto_stories_rounded,
    ),
    _BannerData(
      label: 'MONSOON SALE',
      title: 'Up to 40% Off\nSelected Items',
      subtitle: 'Limited time offer',
      cta: 'View Offers',
      route: '/catalog',
      bgStart: Color(0xFF0A2342),
      bgEnd: Color(0xFF126872),
      accent: Color(0xFF00B4D8),
      icon: Icons.local_offer_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _autoScroll();
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _autoScroll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) => _BannerCard(banner: _banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? context.colors.primary
                    : context.colors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerData {
  final String label;
  final String title;
  final String subtitle;
  final String cta;
  final String route;
  final Color bgStart;
  final Color bgEnd;
  final Color accent;
  final IconData icon;

  const _BannerData({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.route,
    required this.bgStart,
    required this.bgEnd,
    required this.accent,
    required this.icon,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerData banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHorizontal),
      child: GestureDetector(
        onTap: () => context.go(banner.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [banner.bgStart, banner.bgEnd],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -10, top: -20,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: banner.accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                right: 20, bottom: -30,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // Decorative icon
              Positioned(
                right: 24, top: 24,
                child: Icon(
                  banner.icon, size: 64,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: banner.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner.cta,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






