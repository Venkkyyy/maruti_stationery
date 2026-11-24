class CartItemModel {
  final String id;
  final String productId;
  final String name;
  final String image;
  final int price;
  final int qty;
  final int stock;
  final Map<String, String> selectedVariations;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
    required this.stock,
    this.selectedVariations = const {},
  });

  factory CartItemModel.fromMap(String id, Map<String, dynamic> map) {
    return CartItemModel(
      id: id,
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      image: map['image'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      selectedVariations: map['selectedVariations'] is Map
          ? (map['selectedVariations'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'qty': qty,
      'stock': stock,
      'selectedVariations': selectedVariations,
    };
  }
}
