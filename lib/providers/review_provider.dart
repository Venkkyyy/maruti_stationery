import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/review_model.dart';
import 'auth_provider.dart';

part 'review_provider.g.dart';

@riverpod
Future<List<ReviewModel>> productReviews(Ref ref, String productId) async {
  final snap = await FirebaseFirestore.instance
      .collection('reviews')
      .where('productId', isEqualTo: productId)
      .get();
  
  final reviews = snap.docs.map((d) => ReviewModel.fromFirestore(d)).toList();
  reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return reviews;
}

@riverpod
class ReviewNotifier extends _$ReviewNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> addReview(String productId, int rating, String text) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      throw Exception('Must be logged in to review');
    }
    
    state = const AsyncLoading();
    try {
      // First, create the review document
      await FirebaseFirestore.instance.collection('reviews').add({
        'productId': productId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Customer',
        'rating': rating,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update the product's average rating? We'll just fetch reviews in the app and average them there or leave it simple for now since it's just dummy UI fixes.
      // In a real app we'd use a transaction or Cloud Function to update the product's aggregate rating.
      
      state = const AsyncData(null);
      ref.invalidate(productReviewsProvider(productId));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
