import 'dart:async';
import 'package:smart_shopper/data/models/brand_model.dart';
import 'package:smart_shopper/domain/entities/brand.dart';
import 'package:smart_shopper/domain/repositories/brand_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

/// Concrete implementation of [BrandRepository] using ObjectBox.
///
/// This class handles the actual database operations for `Brand` entities.
class BrandBox implements BrandRepository {
  late final Box<BrandModel> _box;

  BrandBox(Store store) {
    _box = store.box<BrandModel>();
  }

  @override
  Stream<List<Brand>> getBrandsStream() {
    final query = _box
        .query()
        .order(BrandModel_.name)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find().map((model) => model.toEntity()).toList());
  }

  @override
  Future<List<Brand>> getAllBrands() async {
    final models = _box.getAll();
    models.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Brand?> getBrandById(int id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<int> addBrand(Brand brand) async {
    final model = BrandModel.fromEntity(brand);
    return _box.put(model);
  }

  @override
  Future<void> updateBrand(Brand brand) async {
    final model = BrandModel.fromEntity(brand);
    _box.put(model);
  }

  @override
  Future<bool> deleteBrand(int id) async {
    return _box.remove(id);
  }
}
