// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$wishlistServiceHash() => r'de0caee52ea8b155a406e466000ea8933f49ec4e';

/// See also [wishlistService].
@ProviderFor(wishlistService)
final wishlistServiceProvider = AutoDisposeProvider<WishlistService>.internal(
  wishlistService,
  name: r'wishlistServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$wishlistServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WishlistServiceRef = AutoDisposeProviderRef<WishlistService>;
String _$watchWishlistHash() => r'b4b3e753b2c2cd218a8b3174859ca7c00b2d37b2';

/// See also [watchWishlist].
@ProviderFor(watchWishlist)
final watchWishlistProvider =
    AutoDisposeStreamProvider<List<ProductModel>>.internal(
      watchWishlist,
      name: r'watchWishlistProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$watchWishlistHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchWishlistRef = AutoDisposeStreamProviderRef<List<ProductModel>>;
String _$wishlistNotifierHash() => r'8d6e15d187479905d28354f2f4f6694b3a1bfeec';

/// See also [WishlistNotifier].
@ProviderFor(WishlistNotifier)
final wishlistNotifierProvider =
    AutoDisposeAsyncNotifierProvider<WishlistNotifier, void>.internal(
      WishlistNotifier.new,
      name: r'wishlistNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$wishlistNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WishlistNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
