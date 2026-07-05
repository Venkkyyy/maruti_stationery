import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

part 'order_provider.g.dart';

@riverpod
OrderService orderService(Ref ref) {
  return OrderService();
}

@riverpod
Stream<List<OrderModel>> watchUserOrders(Ref ref, String userId) {
  return ref.watch(orderServiceProvider).watchUserOrders(userId);
}

@riverpod
Stream<OrderModel?> watchOrder(Ref ref, String orderId) {
  return ref.watch(orderServiceProvider).watchOrder(orderId);
}
