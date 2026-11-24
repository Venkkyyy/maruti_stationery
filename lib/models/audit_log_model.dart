import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String adminName;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String description;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    required this.adminName,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.description,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      adminName: data['adminName'] ?? 'Admin',
      adminEmail: data['adminEmail'] ?? '',
      action: data['action'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminName': adminName,
      'adminEmail': adminEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

