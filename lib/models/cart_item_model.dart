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
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num).toInt(),
      qty: (map['qty'] as num).toInt(),
      stock: (map['stock'] as num).toInt(),
      selectedVariations: map['selectedVariations'] != null 
          ? Map<String, String>.from(map['selectedVariations'])
          : {},
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
