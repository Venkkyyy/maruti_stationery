import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/complete_profile_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_product_list_screen.dart';
import '../../features/admin/screens/admin_add_product_screen.dart';
import '../../features/admin/screens/admin_coupons_screen.dart';
import '../../features/admin/widgets/admin_scaffold.dart';
import '../../features/admin/screens/admin_order_list_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_broadcast_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_edit_product_screen.dart';
import '../../features/admin/screens/admin_coupon_form_screen.dart';
import '../../shared/widgets/not_found_screen.dart';
import '../../models/coupon_model.dart';

final GlobalKey<NavigatorState> adminRootNavigatorKey = GlobalKey<NavigatorState>();

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: adminRootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/auth/complete-profile', builder: (context, state) => const CompleteProfileScreen()),

      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneInputScreen(),
      ),

      // Admin Panel ShellRoute
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(child: child),
        routes: [
          GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),
          GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const AdminProductListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AdminAddProductScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AdminEditProductScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/admin/orders', builder: (context, state) => const AdminOrderListScreen()),
          GoRoute(
            path: '/admin/coupons',
            builder: (context, state) => const AdminCouponsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AdminCouponFormScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AdminCouponFormScreen(
                  existingCoupon: state.extra as CouponModel?,
                ),
              ),
            ],
          ),
          GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoriesScreen()),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminSettingsScreen(),
            routes: [
              GoRoute(
                path: 'broadcast',
                builder: (context, state) => const AdminBroadcastScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
