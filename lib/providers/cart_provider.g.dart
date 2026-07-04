// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartStreamHash() => r'72632f8b96578ce783fbacb492c82e891958d73c';

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

/// See also [cartStream].
@ProviderFor(cartStream)
const cartStreamProvider = CartStreamFamily();

/// See also [cartStream].
class CartStreamFamily extends Family<AsyncValue<List<CartItemModel>>> {
  /// See also [cartStream].
  const CartStreamFamily();

  /// See also [cartStream].
  CartStreamProvider call(String userId) {
    return CartStreamProvider(userId);
  }

  @override
  CartStreamProvider getProviderOverride(
    covariant CartStreamProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cartStreamProvider';
}

/// See also [cartStream].
class CartStreamProvider
    extends AutoDisposeStreamProvider<List<CartItemModel>> {
  /// See also [cartStream].
  CartStreamProvider(String userId)
    : this._internal(
        (ref) => cartStream(ref as CartStreamRef, userId),
        from: cartStreamProvider,
        name: r'cartStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cartStreamHash,
        dependencies: CartStreamFamily._dependencies,
        allTransitiveDependencies: CartStreamFamily._allTransitiveDependencies,
        userId: userId,
      );

  CartStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<CartItemModel>> Function(CartStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CartStreamProvider._internal(
        (ref) => create(ref as CartStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<CartItemModel>> createElement() {
    return _CartStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CartStreamProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CartStreamRef on AutoDisposeStreamProviderRef<List<CartItemModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _CartStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<CartItemModel>>
    with CartStreamRef {
  _CartStreamProviderElement(super.provider);

  @override
  String get userId => (origin as CartStreamProvider).userId;
}

String _$cartNotifierHash() => r'b4e4273486dcd5320c1a28d65f539283386a1df7';

/// See also [CartNotifier].
@ProviderFor(CartNotifier)
final cartNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      CartNotifier,
      List<CartItemModel>
    >.internal(
      CartNotifier.new,
      name: r'cartNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cartNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CartNotifier = AutoDisposeAsyncNotifier<List<CartItemModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
