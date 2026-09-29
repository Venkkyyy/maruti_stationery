import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

const String backToSchoolBannerUrl =
    'https://res.cloudinary.com/eizhyg2w/image/upload/v1788061339/akh8skzpdhwfoi0x5f5w.png';
const String officeEssentialsBannerUrl =
    'https://res.cloudinary.com/eizhyg2w/image/upload/v1788061344/szdutekboywyhejbefsl.jpg';

const Set<String> allowedBannerUrls = {
  backToSchoolBannerUrl,
  officeEssentialsBannerUrl,
};

/// Maps known banner URLs to their tag and title.
/// This ensures banners always have the right tag even if the Firestore
/// document was created before the tag field was introduced.
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

/// Applies the known tag/title for a banner based on its URL,
/// overriding whatever (possibly null) value came from Firestore.
BannerModel _applyKnownTag(BannerModel banner) {
  final meta = _bannerTagMap[banner.imageUrl.trim()];
  if (meta == null) return banner;
  return BannerModel(
    id: banner.id,
    imageUrl: banner.imageUrl,
    isActive: banner.isActive,
    targetCategoryId: banner.targetCategoryId,
    targetProductId: banner.targetProductId,
    tag: meta['tag'],
    title: meta['title'],
    createdAt: banner.createdAt,
  );
}

List<BannerModel> getProfessionalBanners() => [
  BannerModel(
    id: 'back_to_school_offer',
    imageUrl: backToSchoolBannerUrl,
    isActive: true,
    tag: 'back_to_school',
    title: 'Back to School',
    createdAt: DateTime.now(),
  ),
  BannerModel(
    id: 'office_essentials_offer',
    imageUrl: officeEssentialsBannerUrl,
    isActive: true,
    tag: 'office_essentials',
    title: 'Office Essentials',
    createdAt: DateTime.now().subtract(const Duration(seconds: 1)),
  ),
];

final bannerProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final banners = snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .where((b) => allowedBannerUrls.contains(b.imageUrl.trim()))
            .map(_applyKnownTag) // ← inject tag from code
            .toList();

        if (banners.isEmpty) {
          return getProfessionalBanners();
        }

        // Sort client-side to ensure stable order
        banners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return banners;
      });
});

final allBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        final banners = snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .where((b) => allowedBannerUrls.contains(b.imageUrl.trim()))
            .map(_applyKnownTag) // ← inject tag from code
            .toList();

        if (banners.isEmpty) {
          return getProfessionalBanners();
        }

        return banners;
      });
});
