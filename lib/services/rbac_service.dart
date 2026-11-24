import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_model.dart';
import 'admin_audit_service.dart';

/// Granular System Permissions
class AppPermission {
  AppPermission._();

  // Products & Catalog
  static const String productsRead = 'products.read';
  static const String productsCreate = 'products.create';
  static const String productsUpdate = 'products.update';
  static const String productsDelete = 'products.delete';

  // Inventory & Stock
  static const String inventoryRead = 'inventory.read';
  static const String inventoryAdjust = 'inventory.adjust';

  // Orders & Fulfillment
  static const String ordersRead = 'orders.read';
  static const String ordersUpdate = 'orders.update';
  static const String ordersCancel = 'orders.cancel';
  static const String refundsCreate = 'refunds.create';

  // Customers & Privacy
  static const String customersRead = 'customers.read';
  static const String customersExport = 'customers.export';

  // Campaigns & Marketing
  static const String campaignsManage = 'campaigns.manage';
  static const String campaignsPublish = 'campaigns.publish';

  // Storefront CMS
  static const String storefrontManage = 'storefront.manage';

  // Staff & Roles
  static const String staffManage = 'staff.manage';

  // Reports & Analytics
  static const String reportsRead = 'reports.read';
  static const String reportsFinanceRead = 'reports.finance.read';

  // Security & Audit
  static const String securityAuditRead = 'security.audit.read';

  static const List<String> allPermissions = [
    productsRead,
    productsCreate,
    productsUpdate,
    productsDelete,
    inventoryRead,
    inventoryAdjust,
    ordersRead,
    ordersUpdate,
    ordersCancel,
    refundsCreate,
    customersRead,
    customersExport,
    campaignsManage,
    campaignsPublish,
    storefrontManage,
    staffManage,
    reportsRead,
    reportsFinanceRead,
    securityAuditRead,
  ];
}

class RBACService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Role to default permission matrix
  static final Map<StaffRole, Set<String>> _rolePermissionMatrix = {
    StaffRole.superAdmin: AppPermission.allPermissions.toSet(),

    StaffRole.storeManager: {
      AppPermission.productsRead,
      AppPermission.productsCreate,
      AppPermission.productsUpdate,
      AppPermission.productsDelete,
      AppPermission.inventoryRead,
      AppPermission.inventoryAdjust,
      AppPermission.ordersRead,
      AppPermission.ordersUpdate,
      AppPermission.ordersCancel,
      AppPermission.refundsCreate,
      AppPermission.customersRead,
      AppPermission.customersExport,
      AppPermission.campaignsManage,
      AppPermission.campaignsPublish,
      AppPermission.storefrontManage,
      AppPermission.reportsRead,
      AppPermission.reportsFinanceRead,
      AppPermission.securityAuditRead,
    },

    StaffRole.contentManager: {
      AppPermission.productsRead,
      AppPermission.campaignsManage,
      AppPermission.campaignsPublish,
      AppPermission.storefrontManage,
      AppPermission.reportsRead,
    },

    StaffRole.inventoryManager: {
      AppPermission.productsRead,
      AppPermission.productsCreate,
      AppPermission.productsUpdate,
      AppPermission.inventoryRead,
      AppPermission.inventoryAdjust,
      AppPermission.reportsRead,
    },

    StaffRole.orderManager: {
      AppPermission.productsRead,
      AppPermission.inventoryRead,
      AppPermission.ordersRead,
      AppPermission.ordersUpdate,
      AppPermission.ordersCancel,
      AppPermission.refundsCreate,
      AppPermission.customersRead,
    },

    StaffRole.supportStaff: {
      AppPermission.productsRead,
      AppPermission.ordersRead,
      AppPermission.customersRead,
      AppPermission.reportsRead,
    },

    StaffRole.viewer: {
      AppPermission.productsRead,
      AppPermission.inventoryRead,
      AppPermission.ordersRead,
      AppPermission.reportsRead,
    },
  };

  /// Check whether a role + custom overrides possesses a permission
  static bool hasPermission({
    required StaffRole role,
    required String permission,
    List<String> customPermissions = const [],
  }) {
    if (role == StaffRole.superAdmin) return true;
    if (customPermissions.contains(permission)) return true;
    final granted = _rolePermissionMatrix[role] ?? {};
    return granted.contains(permission);
  }

  /// Get current authenticated staff record
  Stream<StaffModel?> streamCurrentStaff() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection('staff').doc(user.uid).snapshots().asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        return StaffModel.fromFirestore(doc);
      }

      // Check if user is fallback Super Admin via email or user doc
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final isAdmin = (userDoc.data()?['isAdmin'] as bool?) ?? false;
      if (isAdmin) {
        return StaffModel(
          id: user.uid,
          name: user.displayName ?? 'Super Admin',
          email: user.email ?? '',
          phone: '',
          role: StaffRole.superAdmin,
          createdAt: DateTime.now(),
        );
      }
      return null;
    });
  }

  /// Guard action execution with audit logging on unauthorized access attempts
  static Future<bool> verifyAndAudit({
    required StaffModel? staff,
    required String requiredPermission,
    required String actionDescription,
  }) async {
    if (staff == null || !staff.isActive) {
      await AdminAuditService.logAction(
        action: 'ACCESS_DENIED_UNAUTHENTICATED',
        targetType: 'security',
        targetId: 'auth_guard',
        description: 'Unauthorized access attempt for "$actionDescription". No active staff session.',
      );
      return false;
    }

    final allowed = hasPermission(
      role: staff.role,
      permission: requiredPermission,
      customPermissions: staff.customPermissions,
    );

    if (!allowed) {
      await AdminAuditService.logAction(
        action: 'ACCESS_DENIED_PERMISSION_REVOKED',
        targetType: 'security',
        targetId: requiredPermission,
        description: 'Staff "${staff.name}" (${staff.role.displayName}) lacked permission "$requiredPermission" to perform "$actionDescription".',
      );
    }

    return allowed;
  }
}

/// Riverpod Providers for RBAC
final rbacServiceProvider = Provider<RBACService>((ref) {
  return RBACService();
});

final currentStaffStreamProvider = StreamProvider<StaffModel?>((ref) {
  return ref.watch(rbacServiceProvider).streamCurrentStaff();
});

final userPermissionsProvider = Provider<Set<String>>((ref) {
  final staff = ref.watch(currentStaffStreamProvider).value;
  if (staff == null || !staff.isActive) return {};
  if (staff.role == StaffRole.superAdmin) {
    return AppPermission.allPermissions.toSet();
  }

  final matrix = RBACService._rolePermissionMatrix[staff.role] ?? {};
  return {...matrix, ...staff.customPermissions};
});

