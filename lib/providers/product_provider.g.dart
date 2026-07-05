// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productService)
final productServiceProvider = ProductServiceProvider._();

final class ProductServiceProvider
    extends $FunctionalProvider<ProductService, ProductService, ProductService>
    with $Provider<ProductService> {
  ProductServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productServiceHash();

  @$internal
  @override
  $ProviderElement<ProductService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProductService create(Ref ref) {
    return productService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductService>(value),
    );
  }
}

String _$productServiceHash() => r'0473fdd2a61f1b9401fe8cd8815ed49e7139952a';

@ProviderFor(getProduct)
final getProductProvider = GetProductFamily._();

final class GetProductProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductModel?>,
          ProductModel?,
          FutureOr<ProductModel?>
        >
    with $FutureModifier<ProductModel?>, $FutureProvider<ProductModel?> {
  GetProductProvider._({
    required GetProductFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getProductProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getProductHash();

  @override
  String toString() {
    return r'getProductProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProductModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProductModel?> create(Ref ref) {
    final argument = this.argument as String;
    return getProduct(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetProductProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getProductHash() => r'fccc3a8e9f560bdb1f6f06fb2dfb835f1ad82a98';

final class GetProductFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProductModel?>, String> {
  GetProductFamily._()
    : super(
        retry: null,
        name: r'getProductProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetProductProvider call(String productId) =>
      GetProductProvider._(argument: productId, from: this);

  @override
  String toString() => r'getProductProvider';
}

@ProviderFor(watchProduct)
final watchProductProvider = WatchProductFamily._();

final class WatchProductProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductModel?>,
          ProductModel?,
          Stream<ProductModel?>
        >
    with $FutureModifier<ProductModel?>, $StreamProvider<ProductModel?> {
  WatchProductProvider._({
    required WatchProductFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchProductProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchProductHash();

  @override
  String toString() {
    return r'watchProductProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ProductModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ProductModel?> create(Ref ref) {
    final argument = this.argument as String;
    return watchProduct(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchProductProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchProductHash() => r'8acf4d43afe30dc9a0a1294f32a0f2a24464d47d';

final class WatchProductFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ProductModel?>, String> {
  WatchProductFamily._()
    : super(
        retry: null,
        name: r'watchProductProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchProductProvider call(String productId) =>
      WatchProductProvider._(argument: productId, from: this);

  @override
  String toString() => r'watchProductProvider';
}

@ProviderFor(getProductsByCategory)
final getProductsByCategoryProvider = GetProductsByCategoryFamily._();

final class GetProductsByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductModel>>,
          List<ProductModel>,
          FutureOr<List<ProductModel>>
        >
    with
        $FutureModifier<List<ProductModel>>,
        $FutureProvider<List<ProductModel>> {
  GetProductsByCategoryProvider._({
    required GetProductsByCategoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getProductsByCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getProductsByCategoryHash();

  @override
  String toString() {
    return r'getProductsByCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductModel>> create(Ref ref) {
    final argument = this.argument as String;
    return getProductsByCategory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetProductsByCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getProductsByCategoryHash() =>
    r'c8756b3879cf7d59fd1d8674957ab7d18d151287';

final class GetProductsByCategoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductModel>>, String> {
  GetProductsByCategoryFamily._()
    : super(
        retry: null,
        name: r'getProductsByCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetProductsByCategoryProvider call(String categoryId) =>
      GetProductsByCategoryProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'getProductsByCategoryProvider';
}

@ProviderFor(getNewArrivals)
final getNewArrivalsProvider = GetNewArrivalsFamily._();

final class GetNewArrivalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductModel>>,
          List<ProductModel>,
          FutureOr<List<ProductModel>>
        >
    with
        $FutureModifier<List<ProductModel>>,
        $FutureProvider<List<ProductModel>> {
  GetNewArrivalsProvider._({
    required GetNewArrivalsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'getNewArrivalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getNewArrivalsHash();

  @override
  String toString() {
    return r'getNewArrivalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductModel>> create(Ref ref) {
    final argument = this.argument as int;
    return getNewArrivals(ref, limit: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetNewArrivalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getNewArrivalsHash() => r'72afeba5cd066d5ce4477708c2df2fe6c12d3e6e';

final class GetNewArrivalsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductModel>>, int> {
  GetNewArrivalsFamily._()
    : super(
        retry: null,
        name: r'getNewArrivalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetNewArrivalsProvider call({int limit = 10}) =>
      GetNewArrivalsProvider._(argument: limit, from: this);

  @override
  String toString() => r'getNewArrivalsProvider';
}

@ProviderFor(getRelatedProducts)
final getRelatedProductsProvider = GetRelatedProductsFamily._();

final class GetRelatedProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductModel>>,
          List<ProductModel>,
          FutureOr<List<ProductModel>>
        >
    with
        $FutureModifier<List<ProductModel>>,
        $FutureProvider<List<ProductModel>> {
  GetRelatedProductsProvider._({
    required GetRelatedProductsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'getRelatedProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getRelatedProductsHash();

  @override
  String toString() {
    return r'getRelatedProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductModel>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return getRelatedProducts(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRelatedProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getRelatedProductsHash() =>
    r'156ff2257201405500ecf56c807ee8fc2ac22830';

final class GetRelatedProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProductModel>>,
          (String, String)
        > {
  GetRelatedProductsFamily._()
    : super(
        retry: null,
        name: r'getRelatedProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetRelatedProductsProvider call(String categoryId, String excludeProductId) =>
      GetRelatedProductsProvider._(
        argument: (categoryId, excludeProductId),
        from: this,
      );

  @override
  String toString() => r'getRelatedProductsProvider';
}
