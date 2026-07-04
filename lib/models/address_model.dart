class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String type; // e.g. Home, Office, Other

  const AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.type,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      type: map['type'] ?? 'Home',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'type': type,
    };
  }
}
