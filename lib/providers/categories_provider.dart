import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

part 'categories_provider.g.dart';

/// Real-time stream of ONLY active categories for customer app.
/// Updates automatically whenever admin adds, updates, or toggles active state.
final activeCategoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('categories')
      .snapshots()
      .map((snap) {
        final cats = snap.docs
            .map((d) => CategoryModel.fromFirestore(d))
            .where((c) => c.isActive)
            .toList();
        cats.sort((a, b) => a.order.compareTo(b.order));
        return cats;
      });
});

@riverpod
Future<List<CategoryModel>> categories(Ref ref) async {
  // Watches the real-time stream so any change in Firestore triggers updates
  return ref.watch(activeCategoriesStreamProvider.future);
}
