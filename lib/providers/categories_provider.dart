import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

part 'categories_provider.g.dart';

@riverpod
Future<List<CategoryModel>> categories(Ref ref) async {
  final snap = await FirebaseFirestore.instance.collection('categories').orderBy('order').get();
  final cats = snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
  return cats;
}
