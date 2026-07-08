// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddressNotifier)
final addressProvider = AddressNotifierProvider._();

final class AddressNotifierProvider
    extends $AsyncNotifierProvider<AddressNotifier, List<AddressModel>> {
  AddressNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressNotifierHash();

  @$internal
  @override
  AddressNotifier create() => AddressNotifier();
}

String _$addressNotifierHash() => r'd22bc521ffbf44f25ed7158da6208247972717a1';

abstract class _$AddressNotifier extends $AsyncNotifier<List<AddressModel>> {
  FutureOr<List<AddressModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AddressModel>>, List<AddressModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AddressModel>>, List<AddressModel>>,
              AsyncValue<List<AddressModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
