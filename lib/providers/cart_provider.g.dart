// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeCoupons)
final activeCouponsProvider = ActiveCouponsProvider._();

final class ActiveCouponsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CouponModel>>,
          List<CouponModel>,
          FutureOr<List<CouponModel>>
        >
    with
        $FutureModifier<List<CouponModel>>,
        $FutureProvider<List<CouponModel>> {
  ActiveCouponsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCouponsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCouponsHash();

  @$internal
  @override
  $FutureProviderElement<List<CouponModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CouponModel>> create(Ref ref) {
    return activeCoupons(ref);
  }
}

String _$activeCouponsHash() => r'83e5ea6d52b7b71c98c692d0b8010d1f72ebd911';

@ProviderFor(AppliedCoupon)
final appliedCouponProvider = AppliedCouponProvider._();

final class AppliedCouponProvider
    extends $NotifierProvider<AppliedCoupon, CouponModel?> {
  AppliedCouponProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appliedCouponProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appliedCouponHash();

  @$internal
  @override
  AppliedCoupon create() => AppliedCoupon();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CouponModel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CouponModel?>(value),
    );
  }
}

String _$appliedCouponHash() => r'91f327ae866d5a3ae3ed8e134c9f45d1c0b01085';

abstract class _$AppliedCoupon extends $Notifier<CouponModel?> {
  CouponModel? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CouponModel?, CouponModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CouponModel?, CouponModel?>,
              CouponModel?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(cartStream)
final cartStreamProvider = CartStreamFamily._();

final class CartStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CartItemModel>>,
          List<CartItemModel>,
          Stream<List<CartItemModel>>
        >
    with
        $FutureModifier<List<CartItemModel>>,
        $StreamProvider<List<CartItemModel>> {
  CartStreamProvider._({
    required CartStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cartStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cartStreamHash();

  @override
  String toString() {
    return r'cartStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CartItemModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CartItemModel>> create(Ref ref) {
    final argument = this.argument as String;
    return cartStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CartStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cartStreamHash() => r'ddc06179ac4f18695b9c589e699a522b5fb7b350';

final class CartStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CartItemModel>>, String> {
  CartStreamFamily._()
    : super(
        retry: null,
        name: r'cartStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CartStreamProvider call(String userId) =>
      CartStreamProvider._(argument: userId, from: this);

  @override
  String toString() => r'cartStreamProvider';
}

@ProviderFor(CartNotifier)
final cartProvider = CartNotifierProvider._();

final class CartNotifierProvider
    extends $AsyncNotifierProvider<CartNotifier, List<CartItemModel>> {
  CartNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartNotifierHash();

  @$internal
  @override
  CartNotifier create() => CartNotifier();
}

String _$cartNotifierHash() => r'733638ff9e56149a94fd5c71a25e8e630fc4683b';

abstract class _$CartNotifier extends $AsyncNotifier<List<CartItemModel>> {
  FutureOr<List<CartItemModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CartItemModel>>, List<CartItemModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CartItemModel>>, List<CartItemModel>>,
              AsyncValue<List<CartItemModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
