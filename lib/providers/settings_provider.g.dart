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
