// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$cartNotifierHash() => r'b4e4273486dcd5320c1a28d65f539283386a1df7';

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
