import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../features/delivery/screens/delivery_login_screen.dart';
import '../../features/delivery/screens/delivery_home_screen.dart';
import '../../features/delivery/screens/delivery_order_detail_screen.dart';

final deliveryRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const DeliveryLoginScreen(),
      ),

      GoRoute(
        path: '/',
        builder: (context, state) => const DeliveryHomeScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DeliveryOrderDetailScreen(orderId: id);
        },
      ),
    ],
  );
});
