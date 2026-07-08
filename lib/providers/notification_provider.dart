import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

part 'notification_provider.g.dart';

@riverpod
Stream<List<NotificationModel>> userNotifications(Ref ref) {
  final user = ref.watch(authStateProvider).value;
  final userId = user?.uid;

  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .where((notification) => notification.userId == null || notification.userId == userId)
            .toList();
      });
}
