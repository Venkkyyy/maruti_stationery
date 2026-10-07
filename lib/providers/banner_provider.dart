import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

const String backToSchoolBannerUrl =
    'https://res.cloudinary.com/eizhyg2w/image/upload/v1788061339/akh8skzpdhwfoi0x5f5w.png';
const String officeEssentialsBannerUrl =
    'https://res.cloudinary.com/eizhyg2w/image/upload/v1788061344/szdutekboywyhejbefsl.jpg';

/// Maps known banner URLs to their tag and title.
const Map<String, Map<String, String>> _bannerTagMap = {
  backToSchoolBannerUrl: {
    'tag': 'back_to_school',
    'title': 'Back to School',
  },
  officeEssentialsBannerUrl: {
    'tag': 'office_essentials',
    'title': 'Office Essentials',
  },
};

BannerModel _applyKnownTag(BannerModel banner) {
  final meta = _bannerTagMap[banner.imageUrl.trim()];
  if (meta == null) return banner;
  return BannerModel(
    id: banner.id,
    imageUrl: banner.imageUrl,
    isActive: banner.isActive,
    targetCategoryId: banner.targetCategoryId,
    targetProductId: banner.targetProductId,
    tag: banner.tag ?? meta['tag'],
    title: banner.title ?? meta['title'],
    createdAt: banner.createdAt,
  );
}

/// Real-time stream of ONLY active banners for customer app.
/// Updates instantly when admin adds, toggles, or removes banners.
final bannerProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final banners = snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .where((b) => b.isActive && b.imageUrl.isNotEmpty)
            .map(_applyKnownTag)
            .toList();

        // Sort client-side by createdAt descending
        banners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return banners;
      });
});

/// Real-time stream of ALL banners for admin management screen.
final allBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .snapshots()
      .map((snapshot) {
        final banners = snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .where((b) => b.imageUrl.isNotEmpty)
            .map(_applyKnownTag)
            .toList();

        banners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return banners;
      });
});
