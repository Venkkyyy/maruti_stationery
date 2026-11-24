import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_section_model.dart';

final homeLayoutStreamProvider = StreamProvider<List<HomeSectionModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('settings')
      .doc('home_layout')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return HomeSectionModel.defaultSections;
    }

    final data = snapshot.data()!;
    final rawList = data['sections'] as List<dynamic>?;
    if (rawList == null || rawList.isEmpty) {
      return HomeSectionModel.defaultSections;
    }

    final sections = <HomeSectionModel>[];
    for (int i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      if (item is Map) {
        sections.add(HomeSectionModel.fromMap(item, fallbackOrder: i));
      }
    }

    if (sections.isEmpty) {
      return HomeSectionModel.defaultSections;
    }

    sections.sort((a, b) => a.order.compareTo(b.order));
    return sections;
  });
});

class HomeLayoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveLayout(List<HomeSectionModel> sections) async {
    final mappedSections = sections.asMap().entries.map((entry) {
      final s = entry.value;
      return s.copyWith(order: entry.key).toMap();
    }).toList();

    await _db.collection('settings').doc('home_layout').set({
      'sections': mappedSections,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resetToDefault() async {
    await saveLayout(HomeSectionModel.defaultSections);
  }
}

final homeLayoutServiceProvider = Provider<HomeLayoutService>((ref) {
  return HomeLayoutService();
});

