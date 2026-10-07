// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchSupportDetails)
final watchSupportDetailsProvider = WatchSupportDetailsProvider._();

final class WatchSupportDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SupportDetailsModel>,
          SupportDetailsModel,
          Stream<SupportDetailsModel>
        >
    with
        $FutureModifier<SupportDetailsModel>,
        $StreamProvider<SupportDetailsModel> {
  WatchSupportDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchSupportDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchSupportDetailsHash();

  @$internal
  @override
  $StreamProviderElement<SupportDetailsModel> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SupportDetailsModel> create(Ref ref) {
    return watchSupportDetails(ref);
  }
}

String _$watchSupportDetailsHash() =>
    r'35ef7cc7253f40a8ba37e84456fe038baaf78acf';

@ProviderFor(watchLoyaltyRule)
final watchLoyaltyRuleProvider = WatchLoyaltyRuleProvider._();

final class WatchLoyaltyRuleProvider
    extends
        $FunctionalProvider<
          AsyncValue<LoyaltyRuleModel>,
          LoyaltyRuleModel,
          Stream<LoyaltyRuleModel>
        >
    with $FutureModifier<LoyaltyRuleModel>, $StreamProvider<LoyaltyRuleModel> {
  WatchLoyaltyRuleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchLoyaltyRuleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchLoyaltyRuleHash();

  @$internal
  @override
  $StreamProviderElement<LoyaltyRuleModel> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LoyaltyRuleModel> create(Ref ref) {
    return watchLoyaltyRule(ref);
  }
}

String _$watchLoyaltyRuleHash() => r'2e8bf1d7e008fc6b122a19de22d661056c29c8dc';

@ProviderFor(watchDeliverySettings)
final watchDeliverySettingsProvider = WatchDeliverySettingsProvider._();

final class WatchDeliverySettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeliverySettingsModel>,
          DeliverySettingsModel,
          Stream<DeliverySettingsModel>
        >
    with
        $FutureModifier<DeliverySettingsModel>,
        $StreamProvider<DeliverySettingsModel> {
  WatchDeliverySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchDeliverySettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchDeliverySettingsHash();

  @$internal
  @override
  $StreamProviderElement<DeliverySettingsModel> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DeliverySettingsModel> create(Ref ref) {
    return watchDeliverySettings(ref);
  }
}

String _$watchDeliverySettingsHash() =>
    r'debc09ed4e6e5a0f28f277d42e2b400b77a7e340';
