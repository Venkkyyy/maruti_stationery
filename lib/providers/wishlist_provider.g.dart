// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wishlistService)
final wishlistServiceProvider = WishlistServiceProvider._();

final class WishlistServiceProvider
    extends
        $FunctionalProvider<WishlistService, WishlistService, WishlistService>
    with $Provider<WishlistService> {
  WishlistServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wishlistServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wishlistServiceHash();

  @$internal
  @override
  $ProviderElement<WishlistService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WishlistService create(Ref ref) {
    return wishlistService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WishlistService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WishlistService>(value),
    );
  }
}

String _$wishlistServiceHash() => r'996c450be5fbfc42f8dbd08a5eb60151cd88c23e';

@ProviderFor(watchWishlist)
final watchWishlistProvider = WatchWishlistProvider._();

final class WatchWishlistProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductModel>>,
          List<ProductModel>,
          Stream<List<ProductModel>>
        >
    with
        $FutureModifier<List<ProductModel>>,
        $StreamProvider<List<ProductModel>> {
  WatchWishlistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchWishlistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchWishlistHash();

  @$internal
  @override
  $StreamProviderElement<List<ProductModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProductModel>> create(Ref ref) {
    return watchWishlist(ref);
  }
}

String _$watchWishlistHash() => r'eeb0c3cc512e97e515f93c28bb214cfc08668403';

@ProviderFor(WishlistNotifier)
final wishlistProvider = WishlistNotifierProvider._();

final class WishlistNotifierProvider
    extends $AsyncNotifierProvider<WishlistNotifier, void> {
  WishlistNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wishlistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wishlistNotifierHash();

  @$internal
  @override
  WishlistNotifier create() => WishlistNotifier();
}

String _$wishlistNotifierHash() => r'8d6e15d187479905d28354f2f4f6694b3a1bfeec';

abstract class _$WishlistNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
