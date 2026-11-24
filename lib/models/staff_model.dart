import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole {
  admin,
  manager,
  orderClerk,
  inventoryClerk;

  String get displayName {
    switch (this) {
      case StaffRole.admin:
        return 'Administrator';
      case StaffRole.manager:
        return 'Store Manager';
      case StaffRole.orderClerk:
        return 'Order Processing Clerk';
      case StaffRole.inventoryClerk:
        return 'Inventory Clerk';
    }
  }
}

class StaffModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final StaffRole role;
  final bool isActive;
  final DateTime createdAt;

  const StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final roleStr = data['role'] ?? 'staff';
    StaffRole role = StaffRole.orderClerk;
    if (roleStr == 'admin') role = StaffRole.admin;
    if (roleStr == 'manager') role = StaffRole.manager;
    if (roleStr == 'inventoryClerk') role = StaffRole.inventoryClerk;

    return StaffModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: role,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

