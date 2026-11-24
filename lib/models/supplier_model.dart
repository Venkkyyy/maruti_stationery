import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String gstin;
  final String category;
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson = '',
    required this.phone,
    this.email = '',
    this.address = '',
    this.gstin = '',
    this.category = 'Stationery',
    required this.createdAt,
  });

  factory SupplierModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupplierModel(
      id: doc.id,
      name: data['name'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      gstin: data['gstin'] ?? '',
      category: data['category'] ?? 'Stationery',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

