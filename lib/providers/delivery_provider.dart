import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/order_model.dart';

import '../../../providers/auth_provider.dart';

final deliveryOrdersStreamProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final userId = ref.watch(authServiceProvider).currentUser?.uid;
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('orders')
      .where('deliveryPartnerId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    return list;
  });
});

final singleOrderProvider = StreamProvider.autoDispose.family<OrderModel, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) throw Exception('Order not found');
    return OrderModel.fromFirestore(doc);
  });
});
