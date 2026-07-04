class CartItemModel {
  final String productId;
  final String name;
  final String image;
  final int price;
  final int qty;
  final int stock;

  const CartItemModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
    required this.stock,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num).toInt(),
      qty: (map['qty'] as num).toInt(),
      stock: (map['stock'] as num).toInt(),
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
    };
  }
}
