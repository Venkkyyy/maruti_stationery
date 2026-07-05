import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../core/errors/app_exception.dart';
import 'auth_provider.dart';

part 'cart_provider.g.dart';

@riverpod
Stream<List<CartItemModel>> cartStream(Ref ref, String userId) {
  return FirebaseFirestore.instance
      .collection('carts')
      .doc(userId)
      .collection('items')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data()))
          .toList());
}

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  Future<List<CartItemModel>> build() async {
    final userId = ref.watch(authStateProvider).value?.uid;
    if (userId == null) return [];
    
    // Watch real-time cart changes
    ref.listen(cartStreamProvider(userId), (_, next) {
      next.whenData((items) => state = AsyncData(items));
    });
    
    return ref.read(cartStreamProvider(userId).future);
  }

  Future<void> addItem(ProductModel product, int qty) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) throw const AppException('Please login to add to cart');
    
    // Check stock before adding
    if (product.stock < qty) throw AppException('Only ${product.stock} items in stock');
    
    final docRef = FirebaseFirestore.instance
        .collection('carts').doc(userId)
        .collection('items').doc(product.id);
    
    final existing = await docRef.get();
    
    if (existing.exists) {
      final currentQty = (existing.data()!['qty'] as int);
      final newQty = currentQty + qty;
      
      // Re-check stock for new total
      if (newQty > product.stock) {
        throw AppException('Cannot add more. Only ${product.stock} in stock.');
      }
      await docRef.update({'qty': newQty});
    } else {
      await docRef.set({
        'productId': product.id,
        'name': product.name,
        'image': product.primaryImage,
        'price': product.price,
        'qty': qty,
        'stock': product.stock,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateQty(String productId, int newQty) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;
    
    if (newQty <= 0) {
      await removeItem(productId);
      return;
    }
    
    await FirebaseFirestore.instance
        .collection('carts').doc(userId)
        .collection('items').doc(productId)
        .update({'qty': newQty});
  }

  Future<void> removeItem(String productId) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;
    
    await FirebaseFirestore.instance
        .collection('carts').doc(userId)
        .collection('items').doc(productId)
        .delete();
  }

  Future<void> clearCart() async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;
    
    final items = await FirebaseFirestore.instance
        .collection('carts').doc(userId)
        .collection('items')
        .get();
    
    // Batch delete — more efficient than deleting one by one
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Computed values helpers
  int get totalItems => state.value?.fold<int>(0, (total, item) => total + item.qty) ?? 0;
  int get subtotal => state.value?.fold<int>(0, (total, item) => total + (item.price * item.qty)) ?? 0;
}
