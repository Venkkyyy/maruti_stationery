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

  const LoyaltyRuleModel({this.pointsPer100 = 10});

  factory LoyaltyRuleModel.fromMap(Map<String, dynamic> data) {
    return LoyaltyRuleModel(
      pointsPer100: (data['pointsPer100'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() => {
        'pointsPer100': pointsPer100,
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
