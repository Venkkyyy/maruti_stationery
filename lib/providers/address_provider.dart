import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/address_model.dart';
import 'auth_provider.dart';

part 'address_provider.g.dart';

@riverpod
class AddressNotifier extends _$AddressNotifier {
  @override
  Future<List<AddressModel>> build() async {
    final userId = ref.watch(authStateProvider).value?.uid;
    if (userId == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .get();

    return snapshot.docs.map((doc) => AddressModel.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  Future<void> addAddress(AddressModel address) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc();
    
    final newAddress = AddressModel(
      id: docRef.id,
      name: address.name,
      phone: address.phone,
      street: address.street,
      city: address.city,
      state: address.state,
      pincode: address.pincode,
      type: address.type,
    );

    await docRef.set(newAddress.toMap());
    
    // Refresh the list
    ref.invalidateSelf();
  }

  Future<void> removeAddress(String addressId) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
        
    ref.invalidateSelf();
  }
}
