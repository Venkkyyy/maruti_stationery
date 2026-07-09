// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchActiveCoupons)
final watchActiveCouponsProvider = WatchActiveCouponsProvider._();

final class WatchActiveCouponsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CouponModel>>,
          List<CouponModel>,
          Stream<List<CouponModel>>
        >
    with
        $FutureModifier<List<CouponModel>>,
        $StreamProvider<List<CouponModel>> {
  WatchActiveCouponsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchActiveCouponsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchActiveCouponsHash();

  @$internal
  @override
  $StreamProviderElement<List<CouponModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CouponModel>> create(Ref ref) {
    return watchActiveCoupons(ref);
  }
}

String _$watchActiveCouponsHash() =>
    r'551960c6fa4e645c5230a40ffa04b77ee7743649';
