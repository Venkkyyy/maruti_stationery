import 'package:flutter_test/flutter_test.dart';
import 'package:maruti_stationery/models/cart_item_model.dart';
import 'package:maruti_stationery/models/review_model.dart';
import 'package:maruti_stationery/core/utils/image_optimizer.dart';

void main() {
  group('CartItemModel Defensive Parsing Tests', () {
    test('parses completely valid map correctly', () {
      final item = CartItemModel.fromMap('item_1', {
        'productId': 'prod_123',
        'name': 'Classmate Notebook 200 Pages',
        'image': 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        'price': 6500,
        'qty': 2,
        'stock': 20,
        'selectedVariations': {'rule': 'Single Line'},
      });

      expect(item.id, equals('item_1'));
      expect(item.productId, equals('prod_123'));
      expect(item.name, equals('Classmate Notebook 200 Pages'));
      expect(item.price, equals(6500));
      expect(item.qty, equals(2));
      expect(item.stock, equals(20));
      expect(item.selectedVariations['rule'], equals('Single Line'));
    });

    test('handles missing, null, or dynamic values without throwing', () {
      final item = CartItemModel.fromMap('item_corrupted', {
        'productId': null,
        'name': null,
        'image': null,
        'price': null,
        'qty': null,
        'stock': null,
        'selectedVariations': null,
      });

      expect(item.id, equals('item_corrupted'));
      expect(item.productId, isEmpty);
      expect(item.name, isEmpty);
      expect(item.price, equals(0));
      expect(item.qty, equals(1));
      expect(item.stock, equals(0));
      expect(item.selectedVariations, isEmpty);
    });

    test('calculates cart item subtotal accurately in paise', () {
      final items = [
        const CartItemModel(
          id: '1',
          productId: 'p1',
          name: 'Pen',
          image: '',
          price: 1000, // ₹10
          qty: 3,
          stock: 10,
        ),
        const CartItemModel(
          id: '2',
          productId: 'p2',
          name: 'Pencil Box',
          image: '',
          price: 4500, // ₹45
          qty: 2,
          stock: 5,
        ),
      ];

      final totalItems = items.fold<int>(0, (acc, item) => acc + item.qty);
      final subtotal = items.fold<int>(0, (acc, item) => acc + (item.price * item.qty));

      expect(totalItems, equals(5));
      expect(subtotal, equals((1000 * 3) + (4500 * 2))); // 12000 paise = ₹120
    });
  });

  group('Review Aggregation Logic Tests', () {
    test('calculates accurate average rating and count', () {
      final reviews = [
        ReviewModel(
          id: 'r1',
          productId: 'p1',
          userId: 'u1',
          userName: 'Alice',
          rating: 5,
          text: 'Great quality notebook',
          createdAt: DateTime.now(),
        ),
        ReviewModel(
          id: 'r2',
          productId: 'p1',
          userId: 'u2',
          userName: 'Bob',
          rating: 4,
          text: 'Good pages, slightly thin cover',
          createdAt: DateTime.now(),
        ),
        ReviewModel(
          id: 'r3',
          productId: 'p1',
          userId: 'u3',
          userName: 'Charlie',
          rating: 5,
          text: 'Very satisfied!',
          createdAt: DateTime.now(),
        ),
      ];

      final totalReviews = reviews.length;
      final sum = reviews.fold<num>(0, (acc, r) => acc + r.rating);
      final average = double.parse((sum / totalReviews).toStringAsFixed(1));

      expect(totalReviews, equals(3));
      expect(sum, equals(14));
      expect(average, equals(4.7));
    });
  });

  group('ImageOptimizer CDN Transformation Tests', () {
    test('transforms Cloudinary URLs with width, height and auto-format', () {
      const original = 'https://res.cloudinary.com/maruti/image/upload/v1234/notebook.jpg';
      final optimized = ImageOptimizer.getThumbnailUrl(original, width: 360, height: 360);

      expect(optimized, contains('c_limit,w_360,h_360,q_auto,f_auto'));
      expect(optimized, startsWith('https://res.cloudinary.com/maruti/image/upload/'));
    });

    test('transforms Unsplash URLs with query parameters', () {
      const original = 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd';
      final optimized = ImageOptimizer.getThumbnailUrl(original, width: 360);

      expect(optimized, contains('w=360'));
      expect(optimized, contains('auto=format'));
    });
  });
}

