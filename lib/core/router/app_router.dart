import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/catalog/screens/product_list_screen.dart';
import '../../features/catalog/screens/product_detail_screen.dart';
import '../../features/catalog/screens/search_screen.dart';
import '../../features/catalog/screens/reviews_screen.dart';
import '../../features/catalog/screens/rate_order_screen.dart';
import '../../features/catalog/screens/review_success_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/orders/screens/order_list_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/checkout/screens/address_screen.dart';
import '../../features/checkout/screens/payment_screen.dart';
import '../../features/checkout/screens/order_confirmation_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_product_list_screen.dart';
import '../../features/catalog/screens/category_list_screen.dart';
import '../../features/home/screens/notifications_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/admin/screens/admin_add_product_screen.dart';
import '../../features/checkout/screens/add_address_screen.dart';
import '../../features/cart/screens/offers_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../shared/widgets/not_found_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneInputScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, state) => OTPScreen(
              verificationId: state.extra as String? ?? 'mock-id',
            ),
          ),
        ],
      ),

      // Main app — ShellRoute for bottom navigation (Home, Catalog, Orders, Profile)
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: 'product/:id',
                builder: (context, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'reviews',
                    builder: (context, state) => ReviewsScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'rate',
                    builder: (context, state) => RateOrderScreen(
                      productId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'success',
                        builder: (context, state) => ReviewSuccessScreen(
                          productId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: '/cart/offers', builder: (context, state) => const OffersScreen()),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrderListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailScreen(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          GoRoute(path: '/categories', builder: (context, state) => const CategoryListScreen()),
        ],
      ),

      // Notifications (outside shell)
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),

      // Profile settings & support (outside shell)
      GoRoute(path: '/profile/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/profile/support', builder: (context, state) => const HelpSupportScreen()),
      GoRoute(path: '/profile/about', builder: (context, state) => const AboutScreen()),

      // Wishlist — outside shell
      GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),

      // Checkout — outside shell (no bottom nav)
      GoRoute(path: '/checkout/address', builder: (context, state) => const AddressScreen()),
      GoRoute(path: '/checkout/address/add', builder: (context, state) => const AddAddressScreen()),
      GoRoute(path: '/checkout/payment', builder: (context, state) => const PaymentScreen()),
      GoRoute(
        path: '/checkout/confirmation',
        builder: (context, state) => OrderConfirmationScreen(
          orderId: state.extra as String? ?? 'ORD-TEMP',
        ),
      ),

      // Admin Panel
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => const AdminProductListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AdminAddProductScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
