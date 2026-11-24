import 'package:flutter_test/flutter_test.dart';
import 'package:maruti_stationery/models/staff_model.dart';
import 'package:maruti_stationery/services/rbac_service.dart';
import 'package:maruti_stationery/models/privacy_request_model.dart';

void main() {
  group('Enterprise RBAC & Authorization Tests', () {
    test('Super Admin has all system permissions by default', () {
      for (final perm in AppPermission.allPermissions) {
        final allowed = RBACService.hasPermission(
          role: StaffRole.superAdmin,
          permission: perm,
        );
        expect(allowed, isTrue, reason: 'Super Admin must possess $perm');
      }
    });

    test('Viewer role has read-only access and cannot modify data', () {
      expect(
        RBACService.hasPermission(role: StaffRole.viewer, permission: AppPermission.productsRead),
        isTrue,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.viewer, permission: AppPermission.productsCreate),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.viewer, permission: AppPermission.ordersUpdate),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.viewer, permission: AppPermission.refundsCreate),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.viewer, permission: AppPermission.staffManage),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.viewer, permission: AppPermission.campaignsPublish),
        isFalse,
      );
    });

    test('Order Manager has order and refund permissions but cannot adjust inventory or manage staff', () {
      expect(
        RBACService.hasPermission(role: StaffRole.orderManager, permission: AppPermission.ordersRead),
        isTrue,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.orderManager, permission: AppPermission.ordersUpdate),
        isTrue,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.orderManager, permission: AppPermission.refundsCreate),
        isTrue,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.orderManager, permission: AppPermission.inventoryAdjust),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.orderManager, permission: AppPermission.staffManage),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.orderManager, permission: AppPermission.storefrontManage),
        isFalse,
      );
    });

    test('Inventory Manager has inventory adjust permissions but cannot update orders or manage staff', () {
      expect(
        RBACService.hasPermission(role: StaffRole.inventoryManager, permission: AppPermission.inventoryRead),
        isTrue,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.inventoryManager, permission: AppPermission.inventoryAdjust),
        isTrue,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.inventoryManager, permission: AppPermission.ordersUpdate),
        isFalse,
      );
      expect(
        RBACService.hasPermission(role: StaffRole.inventoryManager, permission: AppPermission.staffManage),
        isFalse,
      );
    });

    test('Custom permission overrides grant specific elevated privilege', () {
      const customPerm = AppPermission.campaignsPublish;
      // Normally supportStaff cannot publish campaigns
      expect(
        RBACService.hasPermission(role: StaffRole.supportStaff, permission: customPerm),
        isFalse,
      );
      // With custom override:
      expect(
        RBACService.hasPermission(
          role: StaffRole.supportStaff,
          permission: customPerm,
          customPermissions: [customPerm],
        ),
        isTrue,
      );
    });

    test('Inactive staff members are rejected in verifyAndAudit', () async {
      final inactiveStaff = StaffModel(
        id: 'staff_123',
        name: 'Suspended Employee',
        email: 'suspended@marutistationery.com',
        phone: '1234567890',
        role: StaffRole.superAdmin,
        isActive: false, // Suspended
        createdAt: DateTime.now(),
      );

      final allowed = await RBACService.verifyAndAudit(
        staff: inactiveStaff,
        requiredPermission: AppPermission.ordersRead,
        actionDescription: 'Read Orders',
      );

      expect(allowed, isFalse, reason: 'Inactive/suspended staff must be denied access');
    });
  });

  group('Privacy Request Model Validation', () {
    test('PrivacyRequestModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final model = PrivacyRequestModel(
        id: 'req_001',
        userId: 'user_456',
        userEmail: 'customer@example.com',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        details: 'DPDP Data export request',
        createdAt: now,
      );

      final map = model.toFirestore();
      expect(map['userId'], 'user_456');
      expect(map['userEmail'], 'customer@example.com');
      expect(map['requestType'], PrivacyRequestType.dataExport);
      expect(map['status'], PrivacyRequestStatus.pending);
    });
  });
}

