// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderServiceHash() => r'1f7289b625a710b5f100a6806b245c7ade4fae4e';

/// See also [orderService].
@ProviderFor(orderService)
final orderServiceProvider = AutoDisposeProvider<OrderService>.internal(
  orderService,
  name: r'orderServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderServiceRef = AutoDisposeProviderRef<OrderService>;
String _$watchUserOrdersHash() => r'd6b1fb089b7f7ca4749c4a0c0bef84008dd117e9';

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

/// See also [watchUserOrders].
@ProviderFor(watchUserOrders)
const watchUserOrdersProvider = WatchUserOrdersFamily();

/// See also [watchUserOrders].
class WatchUserOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// See also [watchUserOrders].
  const WatchUserOrdersFamily();

  /// See also [watchUserOrders].
  WatchUserOrdersProvider call(String userId) {
    return WatchUserOrdersProvider(userId);
  }

  @override
  WatchUserOrdersProvider getProviderOverride(
    covariant WatchUserOrdersProvider provider,
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
  String? get name => r'watchUserOrdersProvider';
}

/// See also [watchUserOrders].
class WatchUserOrdersProvider
    extends AutoDisposeStreamProvider<List<OrderModel>> {
  /// See also [watchUserOrders].
  WatchUserOrdersProvider(String userId)
    : this._internal(
        (ref) => watchUserOrders(ref as WatchUserOrdersRef, userId),
        from: watchUserOrdersProvider,
        name: r'watchUserOrdersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchUserOrdersHash,
        dependencies: WatchUserOrdersFamily._dependencies,
        allTransitiveDependencies:
            WatchUserOrdersFamily._allTransitiveDependencies,
        userId: userId,
      );

  WatchUserOrdersProvider._internal(
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
    Stream<List<OrderModel>> Function(WatchUserOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchUserOrdersProvider._internal(
        (ref) => create(ref as WatchUserOrdersRef),
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
  AutoDisposeStreamProviderElement<List<OrderModel>> createElement() {
    return _WatchUserOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchUserOrdersProvider && other.userId == userId;
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
mixin WatchUserOrdersRef on AutoDisposeStreamProviderRef<List<OrderModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _WatchUserOrdersProviderElement
    extends AutoDisposeStreamProviderElement<List<OrderModel>>
    with WatchUserOrdersRef {
  _WatchUserOrdersProviderElement(super.provider);

  @override
  String get userId => (origin as WatchUserOrdersProvider).userId;
}

String _$watchOrderHash() => r'1d5bbbf0f892dd3784a672d42c4ba4231a03274d';

/// See also [watchOrder].
@ProviderFor(watchOrder)
const watchOrderProvider = WatchOrderFamily();

/// See also [watchOrder].
class WatchOrderFamily extends Family<AsyncValue<OrderModel?>> {
  /// See also [watchOrder].
  const WatchOrderFamily();

  /// See also [watchOrder].
  WatchOrderProvider call(String orderId) {
    return WatchOrderProvider(orderId);
  }

  @override
  WatchOrderProvider getProviderOverride(
    covariant WatchOrderProvider provider,
  ) {
    return call(provider.orderId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchOrderProvider';
}

/// See also [watchOrder].
class WatchOrderProvider extends AutoDisposeStreamProvider<OrderModel?> {
  /// See also [watchOrder].
  WatchOrderProvider(String orderId)
    : this._internal(
        (ref) => watchOrder(ref as WatchOrderRef, orderId),
        from: watchOrderProvider,
        name: r'watchOrderProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchOrderHash,
        dependencies: WatchOrderFamily._dependencies,
        allTransitiveDependencies: WatchOrderFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  WatchOrderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final String orderId;

  @override
  Override overrideWith(
    Stream<OrderModel?> Function(WatchOrderRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchOrderProvider._internal(
        (ref) => create(ref as WatchOrderRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<OrderModel?> createElement() {
    return _WatchOrderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchOrderProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchOrderRef on AutoDisposeStreamProviderRef<OrderModel?> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _WatchOrderProviderElement
    extends AutoDisposeStreamProviderElement<OrderModel?>
    with WatchOrderRef {
  _WatchOrderProviderElement(super.provider);

  @override
  String get orderId => (origin as WatchOrderProvider).orderId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
