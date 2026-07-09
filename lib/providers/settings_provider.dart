import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

class SupportDetailsModel {
  final String email;
  final String phone;

  SupportDetailsModel({
    required this.email,
    required this.phone,
  });

  factory SupportDetailsModel.fromMap(Map<String, dynamic> data) {
    return SupportDetailsModel(
      email: data['email'] ?? 'support@marutistationery.com',
      phone: data['phone'] ?? '+91 98765 43210',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

@riverpod
Stream<SupportDetailsModel> watchSupportDetails(Ref ref) {
  return FirebaseFirestore.instance
      .collection('settings')
      .doc('support_details')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return SupportDetailsModel.fromMap(snapshot.data()!);
    }
    // Return default values if document doesn't exist
    return SupportDetailsModel(
      email: 'support@marutistationery.com',
      phone: '+91 98765 43210',
    );
  });
}
