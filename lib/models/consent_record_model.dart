import 'package:cloud_firestore/cloud_firestore.dart';

class ConsentRecordModel {
  final String id;
  final String userId;
  final String consentType;
  final bool granted;
  final String? ipAddress;
  final String? deviceInfo;
  final DateTime timestamp;

  const ConsentRecordModel({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.granted,
    this.ipAddress,
    this.deviceInfo,
    required this.timestamp,
  });

  factory ConsentRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConsentRecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      consentType: data['consentType'] ?? '',
      granted: data['granted'] ?? false,
      ipAddress: data['ipAddress'],
      deviceInfo: data['deviceInfo'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'consentType': consentType,
      'granted': granted,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

