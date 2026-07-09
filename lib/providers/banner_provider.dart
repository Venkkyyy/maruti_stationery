import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

final bannerProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final banners = snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .toList();
        // Sort client-side to avoid needing a Firestore composite index
        banners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return banners;
      });
});

final allBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
          .toList());
});
