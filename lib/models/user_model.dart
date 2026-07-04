import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool isAdmin;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
