import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:maruti_stationery/firebase_options.dart';
import 'package:maruti_stationery/services/admin_banner_service.dart';
import 'package:maruti_stationery/models/banner_model.dart';
import 'package:maruti_stationery/services/admin_product_service.dart';
import 'package:maruti_stationery/models/ad_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final bannerService = AdminBannerService();
  final productService = AdminProductService(); // For ads
  
  // 1. Upload Hero Banner
  final heroBannerFile = File(r'C:\Users\vinik\.gemini\antigravity-ide\brain\98c2326a-c6c3-4b43-a97c-e0b07d409b0b\hero_banner_1791054871662.jpg');
  if (heroBannerFile.existsSync()) {
    print('Uploading hero banner...');
    final bannerUrls = await productService.uploadImagesWithTokens([heroBannerFile]);
    if (bannerUrls.isNotEmpty) {
      final bannerData = bannerUrls.first;
      await bannerService.addBanner(
        directImageUrl: bannerData['url']!,
        isActive: true,
        tag: 'back_to_school',
        title: 'Back to School Essentials',
      );
      print('Hero banner added to Firestore.');
    }
  } else {
    print('Hero banner file not found!');
  }

  // 2. Upload Promo Banner as an Ad
  final promoBannerFile = File(r'C:\Users\vinik\.gemini\antigravity-ide\brain\98c2326a-c6c3-4b43-a97c-e0b07d409b0b\promo_banner_1791054888035.jpg');
  if (promoBannerFile.existsSync()) {
    print('Uploading promo banner...');
    final adUrls = await productService.uploadImagesWithTokens([promoBannerFile]);
    if (adUrls.isNotEmpty) {
      final adData = adUrls.first;
      final adModel = AdModel(
        id: FirebaseFirestore.instance.collection('ads').doc().id,
        videoUrl: '', // Provide a fallback if video is required or adapt as needed
        thumbnailUrl: adData['url']!,
        ctaType: AdCtaType.collection,
        ctaValue: 'all',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance.collection('ads').doc(adModel.id).set(adModel.toFirestore());
      print('Promo banner added to Firestore as Ad.');
    }
  } else {
    print('Promo banner file not found!');
  }
  
  exit(0);
}
