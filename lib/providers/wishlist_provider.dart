import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';
import 'auth_provider.dart';

part 'wishlist_provider.g.dart';

@riverpod
WishlistService wishlistService(Ref ref) {
  return WishlistService();
}

@riverpod
Stream<List<ProductModel>> watchWishlist(Ref ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(wishlistServiceProvider).watchWishlist(user.uid);
}

@riverpod
class WishlistNotifier extends _$WishlistNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> add(ProductModel product) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    state = const AsyncLoading();
    try {
      await ref.read(wishlistServiceProvider).addToWishlist(user.uid, product);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> remove(String productId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(wishlistServiceProvider).removeFromWishlist(user.uid, productId);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
