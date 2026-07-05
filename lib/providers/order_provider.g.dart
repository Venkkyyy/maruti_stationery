// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderService)
final orderServiceProvider = OrderServiceProvider._();

final class OrderServiceProvider
    extends $FunctionalProvider<OrderService, OrderService, OrderService>
    with $Provider<OrderService> {
  OrderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderServiceHash();

  @$internal
  @override
  $ProviderElement<OrderService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderService create(Ref ref) {
    return orderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderService>(value),
    );
  }
}

String _$orderServiceHash() => r'db91a1500c6ce21b07e5458d2b1d26fa20fe5df9';

@ProviderFor(watchUserOrders)
final watchUserOrdersProvider = WatchUserOrdersFamily._();

final class WatchUserOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderModel>>,
          List<OrderModel>,
          Stream<List<OrderModel>>
        >
    with $FutureModifier<List<OrderModel>>, $StreamProvider<List<OrderModel>> {
  WatchUserOrdersProvider._({
    required WatchUserOrdersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchUserOrdersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchUserOrdersHash();

  @override
  String toString() {
    return r'watchUserOrdersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<OrderModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OrderModel>> create(Ref ref) {
    final argument = this.argument as String;
    return watchUserOrders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchUserOrdersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchUserOrdersHash() => r'183bf85a8b6533ca7873166788b49b8129e367ee';

final class WatchUserOrdersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<OrderModel>>, String> {
  WatchUserOrdersFamily._()
    : super(
        retry: null,
        name: r'watchUserOrdersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchUserOrdersProvider call(String userId) =>
      WatchUserOrdersProvider._(argument: userId, from: this);

  @override
  String toString() => r'watchUserOrdersProvider';
}

@ProviderFor(watchOrder)
final watchOrderProvider = WatchOrderFamily._();

final class WatchOrderProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderModel?>,
          OrderModel?,
          Stream<OrderModel?>
        >
    with $FutureModifier<OrderModel?>, $StreamProvider<OrderModel?> {
  WatchOrderProvider._({
    required WatchOrderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchOrderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchOrderHash();

  @override
  String toString() {
    return r'watchOrderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OrderModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrderModel?> create(Ref ref) {
    final argument = this.argument as String;
    return watchOrder(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchOrderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchOrderHash() => r'071180ac3103a3b4870b471c39136c5592e869c3';

final class WatchOrderFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OrderModel?>, String> {
  WatchOrderFamily._()
    : super(
        retry: null,
        name: r'watchOrderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchOrderProvider call(String orderId) =>
      WatchOrderProvider._(argument: orderId, from: this);

  @override
  String toString() => r'watchOrderProvider';
}
