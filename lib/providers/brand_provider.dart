import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand_model.dart';
import '../services/admin_brand_service.dart';

final adminBrandServiceProvider = Provider((ref) => AdminBrandService());

final watchBrandsProvider = StreamProvider<List<BrandModel>>((ref) {
  return ref.read(adminBrandServiceProvider).watchBrands();
});
