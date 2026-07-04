// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productServiceHash() => r'199388505ab819bf6ee758b13a384288d334dafb';

/// See also [productService].
@ProviderFor(productService)
final productServiceProvider = AutoDisposeProvider<ProductService>.internal(
  productService,
  name: r'productServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductServiceRef = AutoDisposeProviderRef<ProductService>;
String _$getProductHash() => r'a9fa471e650513cdda8390383506da22c8831009';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [getProduct].
@ProviderFor(getProduct)
const getProductProvider = GetProductFamily();

/// See also [getProduct].
class GetProductFamily extends Family<AsyncValue<ProductModel?>> {
  /// See also [getProduct].
  const GetProductFamily();

  /// See also [getProduct].
  GetProductProvider call(String productId) {
    return GetProductProvider(productId);
  }

  @override
  GetProductProvider getProviderOverride(
    covariant GetProductProvider provider,
  ) {
    return call(provider.productId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getProductProvider';
}

/// See also [getProduct].
class GetProductProvider extends AutoDisposeFutureProvider<ProductModel?> {
  /// See also [getProduct].
  GetProductProvider(String productId)
    : this._internal(
        (ref) => getProduct(ref as GetProductRef, productId),
        from: getProductProvider,
        name: r'getProductProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$getProductHash,
        dependencies: GetProductFamily._dependencies,
        allTransitiveDependencies: GetProductFamily._allTransitiveDependencies,
        productId: productId,
      );

  GetProductProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  Override overrideWith(
    FutureOr<ProductModel?> Function(GetProductRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetProductProvider._internal(
        (ref) => create(ref as GetProductRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProductModel?> createElement() {
    return _GetProductProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetProductProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetProductRef on AutoDisposeFutureProviderRef<ProductModel?> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _GetProductProviderElement
    extends AutoDisposeFutureProviderElement<ProductModel?>
    with GetProductRef {
  _GetProductProviderElement(super.provider);

  @override
  String get productId => (origin as GetProductProvider).productId;
}

String _$watchProductHash() => r'8d44ff6d570af407e670cd86eb8e9601491d03a9';

/// See also [watchProduct].
@ProviderFor(watchProduct)
const watchProductProvider = WatchProductFamily();

/// See also [watchProduct].
class WatchProductFamily extends Family<AsyncValue<ProductModel?>> {
  /// See also [watchProduct].
  const WatchProductFamily();

  /// See also [watchProduct].
  WatchProductProvider call(String productId) {
    return WatchProductProvider(productId);
  }

  @override
  WatchProductProvider getProviderOverride(
    covariant WatchProductProvider provider,
  ) {
    return call(provider.productId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchProductProvider';
}

/// See also [watchProduct].
class WatchProductProvider extends AutoDisposeStreamProvider<ProductModel?> {
  /// See also [watchProduct].
  WatchProductProvider(String productId)
    : this._internal(
        (ref) => watchProduct(ref as WatchProductRef, productId),
        from: watchProductProvider,
        name: r'watchProductProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchProductHash,
        dependencies: WatchProductFamily._dependencies,
        allTransitiveDependencies:
            WatchProductFamily._allTransitiveDependencies,
        productId: productId,
      );

  WatchProductProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  Override overrideWith(
    Stream<ProductModel?> Function(WatchProductRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchProductProvider._internal(
        (ref) => create(ref as WatchProductRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<ProductModel?> createElement() {
    return _WatchProductProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchProductProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchProductRef on AutoDisposeStreamProviderRef<ProductModel?> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _WatchProductProviderElement
    extends AutoDisposeStreamProviderElement<ProductModel?>
    with WatchProductRef {
  _WatchProductProviderElement(super.provider);

  @override
  String get productId => (origin as WatchProductProvider).productId;
}

String _$getProductsByCategoryHash() =>
    r'1c029c3b60003232906c544bb356b3f0cb465524';

/// See also [getProductsByCategory].
@ProviderFor(getProductsByCategory)
const getProductsByCategoryProvider = GetProductsByCategoryFamily();

/// See also [getProductsByCategory].
class GetProductsByCategoryFamily
    extends Family<AsyncValue<List<ProductModel>>> {
  /// See also [getProductsByCategory].
  const GetProductsByCategoryFamily();

  /// See also [getProductsByCategory].
  GetProductsByCategoryProvider call(String categoryId) {
    return GetProductsByCategoryProvider(categoryId);
  }

  @override
  GetProductsByCategoryProvider getProviderOverride(
    covariant GetProductsByCategoryProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getProductsByCategoryProvider';
}

/// See also [getProductsByCategory].
class GetProductsByCategoryProvider
    extends AutoDisposeFutureProvider<List<ProductModel>> {
  /// See also [getProductsByCategory].
  GetProductsByCategoryProvider(String categoryId)
    : this._internal(
        (ref) =>
            getProductsByCategory(ref as GetProductsByCategoryRef, categoryId),
        from: getProductsByCategoryProvider,
        name: r'getProductsByCategoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$getProductsByCategoryHash,
        dependencies: GetProductsByCategoryFamily._dependencies,
        allTransitiveDependencies:
            GetProductsByCategoryFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  GetProductsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    FutureOr<List<ProductModel>> Function(GetProductsByCategoryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetProductsByCategoryProvider._internal(
        (ref) => create(ref as GetProductsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ProductModel>> createElement() {
    return _GetProductsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetProductsByCategoryProvider &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetProductsByCategoryRef
    on AutoDisposeFutureProviderRef<List<ProductModel>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _GetProductsByCategoryProviderElement
    extends AutoDisposeFutureProviderElement<List<ProductModel>>
    with GetProductsByCategoryRef {
  _GetProductsByCategoryProviderElement(super.provider);

  @override
  String get categoryId => (origin as GetProductsByCategoryProvider).categoryId;
}

String _$getNewArrivalsHash() => r'e541383396b27b01fc623ceeb67ed07aedb0f0c2';

/// See also [getNewArrivals].
@ProviderFor(getNewArrivals)
const getNewArrivalsProvider = GetNewArrivalsFamily();

/// See also [getNewArrivals].
class GetNewArrivalsFamily extends Family<AsyncValue<List<ProductModel>>> {
  /// See also [getNewArrivals].
  const GetNewArrivalsFamily();

  /// See also [getNewArrivals].
  GetNewArrivalsProvider call({int limit = 10}) {
    return GetNewArrivalsProvider(limit: limit);
  }

  @override
  GetNewArrivalsProvider getProviderOverride(
    covariant GetNewArrivalsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getNewArrivalsProvider';
}

/// See also [getNewArrivals].
class GetNewArrivalsProvider
    extends AutoDisposeFutureProvider<List<ProductModel>> {
  /// See also [getNewArrivals].
  GetNewArrivalsProvider({int limit = 10})
    : this._internal(
        (ref) => getNewArrivals(ref as GetNewArrivalsRef, limit: limit),
        from: getNewArrivalsProvider,
        name: r'getNewArrivalsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$getNewArrivalsHash,
        dependencies: GetNewArrivalsFamily._dependencies,
        allTransitiveDependencies:
            GetNewArrivalsFamily._allTransitiveDependencies,
        limit: limit,
      );

  GetNewArrivalsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<ProductModel>> Function(GetNewArrivalsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetNewArrivalsProvider._internal(
        (ref) => create(ref as GetNewArrivalsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ProductModel>> createElement() {
    return _GetNewArrivalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetNewArrivalsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetNewArrivalsRef on AutoDisposeFutureProviderRef<List<ProductModel>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _GetNewArrivalsProviderElement
    extends AutoDisposeFutureProviderElement<List<ProductModel>>
    with GetNewArrivalsRef {
  _GetNewArrivalsProviderElement(super.provider);

  @override
  int get limit => (origin as GetNewArrivalsProvider).limit;
}

String _$getRelatedProductsHash() =>
    r'06974b6470f6ea32c415b56166337297431278ba';

/// See also [getRelatedProducts].
@ProviderFor(getRelatedProducts)
const getRelatedProductsProvider = GetRelatedProductsFamily();

/// See also [getRelatedProducts].
class GetRelatedProductsFamily extends Family<AsyncValue<List<ProductModel>>> {
  /// See also [getRelatedProducts].
  const GetRelatedProductsFamily();

  /// See also [getRelatedProducts].
  GetRelatedProductsProvider call(String categoryId, String excludeProductId) {
    return GetRelatedProductsProvider(categoryId, excludeProductId);
  }

  @override
  GetRelatedProductsProvider getProviderOverride(
    covariant GetRelatedProductsProvider provider,
  ) {
    return call(provider.categoryId, provider.excludeProductId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getRelatedProductsProvider';
}

/// See also [getRelatedProducts].
class GetRelatedProductsProvider
    extends AutoDisposeFutureProvider<List<ProductModel>> {
  /// See also [getRelatedProducts].
  GetRelatedProductsProvider(String categoryId, String excludeProductId)
    : this._internal(
        (ref) => getRelatedProducts(
          ref as GetRelatedProductsRef,
          categoryId,
          excludeProductId,
        ),
        from: getRelatedProductsProvider,
        name: r'getRelatedProductsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$getRelatedProductsHash,
        dependencies: GetRelatedProductsFamily._dependencies,
        allTransitiveDependencies:
            GetRelatedProductsFamily._allTransitiveDependencies,
        categoryId: categoryId,
        excludeProductId: excludeProductId,
      );

  GetRelatedProductsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
    required this.excludeProductId,
  }) : super.internal();

  final String categoryId;
  final String excludeProductId;

  @override
  Override overrideWith(
    FutureOr<List<ProductModel>> Function(GetRelatedProductsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetRelatedProductsProvider._internal(
        (ref) => create(ref as GetRelatedProductsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
        excludeProductId: excludeProductId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ProductModel>> createElement() {
    return _GetRelatedProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRelatedProductsProvider &&
        other.categoryId == categoryId &&
        other.excludeProductId == excludeProductId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);
    hash = _SystemHash.combine(hash, excludeProductId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetRelatedProductsRef
    on AutoDisposeFutureProviderRef<List<ProductModel>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;

  /// The parameter `excludeProductId` of this provider.
  String get excludeProductId;
}

class _GetRelatedProductsProviderElement
    extends AutoDisposeFutureProviderElement<List<ProductModel>>
    with GetRelatedProductsRef {
  _GetRelatedProductsProviderElement(super.provider);

  @override
  String get categoryId => (origin as GetRelatedProductsProvider).categoryId;
  @override
  String get excludeProductId =>
      (origin as GetRelatedProductsProvider).excludeProductId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
