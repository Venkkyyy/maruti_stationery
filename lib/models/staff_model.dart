import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole {
  superAdmin,
  storeManager,
  contentManager,
  inventoryManager,
  orderManager,
  supportStaff,
  viewer;

  String get displayName {
    switch (this) {
      case StaffRole.superAdmin:
        return 'Super Administrator';
      case StaffRole.storeManager:
        return 'Store Manager';
      case StaffRole.contentManager:
        return 'Content Manager';
      case StaffRole.inventoryManager:
        return 'Inventory Manager';
      case StaffRole.orderManager:
        return 'Order Processing Manager';
      case StaffRole.supportStaff:
        return 'Customer Support Staff';
      case StaffRole.viewer:
        return 'Auditor / Viewer (Read-Only)';
    }
  }

  // Backward compatibility alias getters
  static StaffRole get admin => StaffRole.superAdmin;
  static StaffRole get manager => StaffRole.storeManager;
  static StaffRole get orderClerk => StaffRole.orderManager;
  static StaffRole get inventoryClerk => StaffRole.inventoryManager;
}

class StaffModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final StaffRole role;
  final List<String> customPermissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.customPermissions = const [],
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final roleStr = (data['role'] as String?)?.toLowerCase() ?? 'viewer';

    StaffRole role = StaffRole.viewer;
    if (roleStr == 'superadmin' || roleStr == 'admin') role = StaffRole.superAdmin;
    if (roleStr == 'storemanager' || roleStr == 'manager') role = StaffRole.storeManager;
    if (roleStr == 'contentmanager') role = StaffRole.contentManager;
    if (roleStr == 'inventorymanager' || roleStr == 'inventoryclerk') role = StaffRole.inventoryManager;
    if (roleStr == 'ordermanager' || roleStr == 'orderclerk') role = StaffRole.orderManager;
    if (roleStr == 'supportstaff' || roleStr == 'support') role = StaffRole.supportStaff;
    if (roleStr == 'viewer') role = StaffRole.viewer;

    final rawPerms = data['customPermissions'] as List<dynamic>? ?? [];

    return StaffModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: role,
      customPermissions: rawPerms.map((e) => e.toString()).toList(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'customPermissions': customPermissions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }

  StaffModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    List<String>? customPermissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      customPermissions: customPermissions ?? this.customPermissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
