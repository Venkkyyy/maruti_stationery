import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final reference = _db.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  Future<void> deleteData({required String path}) async {
    final reference = _db.doc(path);
    await reference.delete();
  }

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _db.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      return snapshot.docs
          .map((doc) => builder(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
}
