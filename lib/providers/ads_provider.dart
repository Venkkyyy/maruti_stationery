import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ad_model.dart';

final _db = FirebaseFirestore.instance;

/// Stream of all active ads, filtered by date window, sorted by sortOrder.
/// Ads with no startDate/endDate are always included while isActive is true.
final activeAdsProvider = StreamProvider<List<AdModel>>((ref) {
  return _db
      .collection('ads')
      .where('isActive', isEqualTo: true)
      .orderBy('sortOrder')
      .snapshots()
      .map((snap) {
        final now = DateTime.now();
        return snap.docs
            .map(AdModel.fromFirestore)
            .where((ad) {
              final afterStart = ad.startDate == null || now.isAfter(ad.startDate!);
              final beforeEnd  = ad.endDate == null   || now.isBefore(ad.endDate!);
              return afterStart && beforeEnd;
            })
            .toList();
      });
});

/// Stream of ALL ads (active + inactive) for the admin panel.
final allAdsProvider = StreamProvider<List<AdModel>>((ref) {
  return _db
      .collection('ads')
      .orderBy('sortOrder')
      .snapshots()
      .map((snap) => snap.docs.map(AdModel.fromFirestore).toList());
});

/// Logs an impression for [adId] (increments counter in Firestore).
Future<void> logAdImpression(String adId) async {
  await _db.collection('ads').doc(adId).update({
    'impressions': FieldValue.increment(1),
  });
}

/// Logs a click for [adId] (increments counter in Firestore).
Future<void> logAdClick(String adId) async {
  await _db.collection('ads').doc(adId).update({
    'clicks': FieldValue.increment(1),
  });
}

/// Saves (creates or updates) an ad document in Firestore.
Future<void> saveAd(AdModel ad) async {
  final ref = ad.id.isEmpty
      ? _db.collection('ads').doc()
      : _db.collection('ads').doc(ad.id);

  final data = ad.toFirestore();
  if (ad.id.isEmpty) {
    data['createdAt'] = FieldValue.serverTimestamp();
  }
  await ref.set(data, SetOptions(merge: true));
}

/// Deletes an ad document and its associated media from Cloudinary.
Future<void> deleteAd(String adId) async {
  final doc = await _db.collection('ads').doc(adId).get();
  if (doc.exists) {
    final data = doc.data() as Map<String, dynamic>;
    final videoToken = data['videoDeleteToken'] as String?;
    final thumbToken = data['thumbnailDeleteToken'] as String?;
    
    if (videoToken != null && videoToken.isNotEmpty) {
      try {
        await _deleteCloudinaryByToken(videoToken);
      } catch (e) {
        print('Warning: Failed to delete video: $e');
      }
    }
    if (thumbToken != null && thumbToken.isNotEmpty) {
      try {
        await _deleteCloudinaryByToken(thumbToken);
      } catch (e) {
        print('Warning: Failed to delete thumbnail: $e');
      }
    }
  }
  await _db.collection('ads').doc(adId).delete();
}

Future<void> _deleteCloudinaryByToken(String deleteToken) async {
  final url = Uri.parse('https://api.cloudinary.com/v1_1/eizhyg2w/delete_by_token');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': deleteToken}),
  );
  if (response.statusCode != 200) {
    print('Cloudinary delete_by_token returned ${response.statusCode}: ${response.body}');
  }
}

/// Toggles the isActive field on an ad.
Future<void> toggleAdActive(String adId, bool isActive) async {
  await _db.collection('ads').doc(adId).update({'isActive': isActive});
}
