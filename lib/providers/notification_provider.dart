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

/// Deletes a single notification document from Firestore.
Future<void> deleteNotification(String notificationId) async {
  await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
}

/// Clears all notifications visible to the current user.
/// For global notifications (userId == null) it deletes the document entirely.
/// This is safe because admins re-create broadcasts when needed.
Future<void> clearAllNotifications(List<NotificationModel> notifications) async {
  final batch = FirebaseFirestore.instance.batch();
  for (final notif in notifications) {
    batch.delete(FirebaseFirestore.instance.collection('notifications').doc(notif.id));
  }
  await batch.commit();
}
