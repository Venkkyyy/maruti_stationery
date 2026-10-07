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
    return SupportDetailsModel(
      email: 'support@marutistationery.com',
      phone: '+91 98765 43210',
    );
  });
}

// ── Loyalty Rule ─────────────────────────────────────────────────────────────

class LoyaltyRuleModel {
  /// Points earned per ₹100 spent (e.g. 10 means 10 pts per ₹100)
  final int pointsPer100;
  
  /// Number of points required to get ₹1 off.
  final int pointsToRupeeRatio;

  const LoyaltyRuleModel({
    this.pointsPer100 = 10,
    this.pointsToRupeeRatio = 10,
  });

  factory LoyaltyRuleModel.fromMap(Map<String, dynamic> data) {
    return LoyaltyRuleModel(
      pointsPer100: (data['pointsPer100'] as num?)?.toInt() ?? 10,
      pointsToRupeeRatio: (data['pointsToRupeeRatio'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() => {
        'pointsPer100': pointsPer100,
        'pointsToRupeeRatio': pointsToRupeeRatio,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Calculate points for a given total (in paise)
  int calculatePoints(int totalPaise) {
    // totalPaise ÷ 10000 = number of ₹100 units (since 100 rupees = 10000 paise)
    final hundreds = totalPaise ~/ 10000;
    return hundreds * pointsPer100;
  }
}

@riverpod
Stream<LoyaltyRuleModel> watchLoyaltyRule(Ref ref) {
  return FirebaseFirestore.instance
      .collection('settings')
      .doc('loyalty_rule')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return LoyaltyRuleModel.fromMap(snapshot.data()!);
    }
    return const LoyaltyRuleModel();
  });
}

// ── Delivery Settings ────────────────────────────────────────────────────────

class DeliverySettingsModel {
  final int fee; // delivery fee in paise (e.g., 4000 for ₹40)
  final int freeThreshold; // order amount above which delivery is free in paise (e.g., 50000 for ₹500)

  const DeliverySettingsModel({
    this.fee = 4000,
    this.freeThreshold = 50000,
  });

  factory DeliverySettingsModel.fromMap(Map<String, dynamic> data) {
    return DeliverySettingsModel(
      fee: (data['fee'] as num?)?.toInt() ?? 4000,
      freeThreshold: (data['freeThreshold'] as num?)?.toInt() ?? 50000,
    );
  }

  Map<String, dynamic> toMap() => {
        'fee': fee,
        'freeThreshold': freeThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
  /// Calculates the applicable delivery fee based on subtotal
  int calculateFee(int subtotalPaise) {
    if (subtotalPaise >= freeThreshold) {
      return 0; // free delivery
    }
    return fee;
  }
}

@riverpod
Stream<DeliverySettingsModel> watchDeliverySettings(Ref ref) {
  return FirebaseFirestore.instance
      .collection('settings')
      .doc('delivery_settings')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return DeliverySettingsModel.fromMap(snapshot.data()!);
    }
    return const DeliverySettingsModel();
  });
}
