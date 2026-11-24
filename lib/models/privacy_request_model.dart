import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyRequestType {
  static const String dataExport = 'data_export';
  static const String accountDeletion = 'account_deletion';
  static const String dataCorrection = 'data_correction';
  static const String consentWithdrawal = 'consent_withdrawal';
}

class PrivacyRequestStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String rejected = 'rejected';
}

class PrivacyRequestModel {
  final String id;
  final String userId;
  final String userEmail;
  final String requestType;
  final String status;
  final String? details;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PrivacyRequestModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.requestType,
    this.status = PrivacyRequestStatus.pending,
    this.details,
    this.resolutionNotes,
    required this.createdAt,
    this.completedAt,
  });

  factory PrivacyRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PrivacyRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      requestType: data['requestType'] ?? PrivacyRequestType.dataExport,
      status: data['status'] ?? PrivacyRequestStatus.pending,
      details: data['details'],
      resolutionNotes: data['resolutionNotes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'requestType': requestType,
      'status': status,
      'details': details,
      'resolutionNotes': resolutionNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }
}

