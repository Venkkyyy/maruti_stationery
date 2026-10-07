import 'package:firebase_auth/firebase_auth.dart';
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

@Riverpod(keepAlive: true)
class ReviewNotifier extends _$ReviewNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> addReview(String productId, int rating, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Must be logged in to review');
    }
    
    state = const AsyncLoading();
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'productId': productId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Customer',
        'rating': rating,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': [],
        'dislikedBy': [],
      });
      
      state = const AsyncData(null);
      ref.invalidate(productReviewsProvider(productId));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId, String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be logged in');

    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
      ref.invalidate(productReviewsProvider(productId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleLike(String reviewId, String productId, bool isLike) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be logged in');

    try {
      final docRef = FirebaseFirestore.instance.collection('reviews').doc(reviewId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
      List<String> dislikedBy = List<String>.from(data['dislikedBy'] ?? []);

      if (isLike) {
        if (likedBy.contains(user.uid)) {
          likedBy.remove(user.uid);
        } else {
          likedBy.add(user.uid);
          dislikedBy.remove(user.uid);
        }
      } else {
        if (dislikedBy.contains(user.uid)) {
          dislikedBy.remove(user.uid);
        } else {
          dislikedBy.add(user.uid);
          likedBy.remove(user.uid);
        }
      }

      await docRef.update({
        'likedBy': likedBy,
        'dislikedBy': dislikedBy,
      });

      ref.invalidate(productReviewsProvider(productId));
    } catch (e) {
      rethrow;
    }
  }
}
