import 'dart:async';
import 'package:smart_shopper/data/models/brand_model.dart';
import 'package:smart_shopper/domain/entities/brand.dart';
import 'package:smart_shopper/domain/repositories/brand_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';
import 'package:smart_shopper/objectbox_helper.dart';

/// Concrete implementation of [BrandRepository] using ObjectBox.
///
/// This class handles the actual database operations for `Brand` entities.
class BrandRepositoryImpl implements BrandRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<BrandModel> _brandBox;

  BrandRepositoryImpl(this._objectBoxHelper) {
    _brandBox = _objectBoxHelper.store.box<BrandModel>();
  }

  @override
  Stream<List<Brand>> getBrandsStream() {
    final query = _brandBox
        .query()
        .order(BrandModel_.name)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find().map((model) => model.toEntity()).toList());
  }

  @override
  Future<List<Brand>> getAllBrands() async {
    final models = _brandBox.getAll();
    models.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Brand?> getBrandById(int id) async {
    final model = _brandBox.get(id);
    return model?.toEntity();
  }

  @override
  Future<int> addBrand(Brand brand) async {
    // ObjectBox will treat an ID of 0 as a new entity.
    final model = BrandModel.fromEntity(brand);
    return _brandBox.put(model);
  }

  @override
  Future<void> updateBrand(Brand brand) async {
    // The `put` method handles both inserts and updates.
    final model = BrandModel.fromEntity(brand);
    _brandBox.put(model);
  }

  @override
  Future<bool> deleteBrand(int id) async {
    return _brandBox.remove(id);
  }
}
