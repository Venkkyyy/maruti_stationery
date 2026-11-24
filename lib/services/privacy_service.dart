import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../models/privacy_request_model.dart';
import '../models/consent_record_model.dart';
import 'admin_audit_service.dart';

class PrivacyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ───────────────────────────────────────────────────────────────────────────
  // 1. DATA EXPORT (Right to Data Portability — DPDP Act 2023)
  // ───────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final Map<String, dynamic> exportPackage = {
      'exportedAt': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'app': 'Maruti Stationery',
    };

    try {
      // 1. Profile Data
      final userDoc = await _db.collection('users').doc(userId).get();
      exportPackage['profile'] = userDoc.data() ?? {};

      // 2. Saved Addresses
      final addressesSnap = await _db.collection('users').doc(userId).collection('addresses').get();
      exportPackage['addresses'] = addressesSnap.docs.map((d) => d.data()).toList();

      // 3. Orders History
      final ordersSnap = await _db.collection('orders').where('userId', isEqualTo: userId).get();
      exportPackage['orders'] = ordersSnap.docs.map((d) => d.data()).toList();

      // 4. Wishlist
      final wishlistSnap = await _db.collection('wishlists').doc(userId).collection('items').get();
      exportPackage['wishlist'] = wishlistSnap.docs.map((d) => d.data()).toList();

      // 5. Product Reviews Written
      final reviewsSnap = await _db.collection('reviews').where('userId', isEqualTo: userId).get();
      exportPackage['reviews'] = reviewsSnap.docs.map((d) => d.data()).toList();

      // 6. Consent History
      final consentSnap = await _db.collection('consent_records').where('userId', isEqualTo: userId).get();
      exportPackage['consentHistory'] = consentSnap.docs.map((d) => d.data()).toList();

      // Record audit event
      await AdminAuditService.logAction(
        action: 'DATA_EXPORT_COMPLETED',
        targetType: 'privacy',
        targetId: userId,
        description: 'Customer data export compiled for user "$userId".',
      );

      return exportPackage;
    } catch (e) {
      throw AppException('Failed to compile data export: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. CONSENT MANAGEMENT (DPDP Act 2023 / Rules 2025)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> recordConsent({
    required String userId,
    required String consentType,
    required bool granted,
  }) async {
    final id = const Uuid().v4();
    final consent = ConsentRecordModel(
      id: id,
      userId: userId,
      consentType: consentType,
      granted: granted,
      deviceInfo: defaultTargetPlatform.name,
      timestamp: DateTime.now(),
    );

    await _db.collection('consent_records').doc(id).set(consent.toFirestore());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. DATA CORRECTION & GRIEVANCE REQUESTS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> submitCorrectionRequest({
    required String userId,
    required String userEmail,
    required String details,
  }) async {
    final id = const Uuid().v4();
    final req = PrivacyRequestModel(
      id: id,
      userId: userId,
      userEmail: userEmail,
      requestType: PrivacyRequestType.dataCorrection,
      details: details,
      createdAt: DateTime.now(),
    );

    await _db.collection('privacy_requests').doc(id).set(req.toFirestore());

    await AdminAuditService.logAction(
      action: 'DATA_CORRECTION_REQUESTED',
      targetType: 'privacy',
      targetId: id,
      description: 'Customer "$userEmail" requested personal data correction: $details',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. MULTI-STEP ACCOUNT DELETION WORKFLOW
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> processAccountDeletion({
    required String userId,
    String? reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      throw const AppException('Unauthorized: Authentication required to delete account.');
    }

    try {
      // 1. Record Deletion Request in Legal Audit Trail
      final deletionLogId = const Uuid().v4();
      await _db.collection('deletion_requests').doc(deletionLogId).set({
        'userId': userId,
        'userEmail': user.email ?? '',
        'requestedAt': FieldValue.serverTimestamp(),
        'reason': reason ?? 'User self-requested account deletion',
        'status': 'completed',
        'retentionPolicy': 'Financial order lines retained per GST statutory regulations; PII anonymized.',
      });

      final batch = _db.batch();

      // 2. Delete Cart Items
      final cartSnap = await _db.collection('carts').doc(userId).collection('items').get();
      for (final doc in cartSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection('carts').doc(userId));

      // 3. Delete Wishlist Items
      final wishlistSnap = await _db.collection('wishlists').doc(userId).collection('items').get();
      for (final doc in wishlistSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection('wishlists').doc(userId));

      // 4. Delete Saved Addresses
      final addressesSnap = await _db.collection('users').doc(userId).collection('addresses').get();
      for (final doc in addressesSnap.docs) {
        batch.delete(doc.reference);
      }

      // 5. Delete FCM device tokens
      final tokensSnap = await _db.collection('users').doc(userId).collection('fcm_tokens').get();
      for (final doc in tokensSnap.docs) {
        batch.delete(doc.reference);
      }

      // 6. Anonymize Customer PII on Past Orders (Statutory GST Compliance)
      // Orders must be kept for financial audits, but personal identifiers are detached
      final ordersSnap = await _db.collection('orders').where('userId', isEqualTo: userId).get();
      for (final doc in ordersSnap.docs) {
        batch.update(doc.reference, {
          'customerName': 'Anonymized Customer',
          'customerPhone': '******',
          'customerEmail': 'anonymized@marutistationery.com',
          'address.name': 'Anonymized Customer',
          'address.phone': '******',
          'isAnonymized': true,
          'anonymizedAt': FieldValue.serverTimestamp(),
        });
      }

      // 7. Delete User Profile Document
      batch.delete(_db.collection('users').doc(userId));

      // Commit Batch Operations
      await batch.commit();

      // 8. Delete Firebase Auth Account
      await user.delete();

      // 9. Sign out from Google Auth
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      // 10. Clear Local Storage and SharedPreferences Caches
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await AdminAuditService.logAction(
        action: 'ACCOUNT_DELETION_COMPLETED',
        targetType: 'privacy',
        targetId: userId,
        description: 'Account $userId deleted and PII anonymized across past orders.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AppException(
          'Security check: Please log out and sign in again before deleting your account.',
        );
      }
      throw AppException(e.message ?? 'Account deletion failed.');
    } catch (e) {
      throw AppException('An error occurred during account deletion: $e');
    }
  }
}

