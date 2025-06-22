import 'dart:async';

import 'package:smart_shopper/data/models/sub_brand_model.dart';
import 'package:smart_shopper/domain/entities/sub_brand.dart';
import 'package:smart_shopper/domain/repositories/sub_brand_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

/// Concrete implementation of [ISubBrandRepository] using ObjectBox.
/// This class manages all CRUD operations for the [SubBrand] entity.
// MARK: OBJECTBOX
class SubBrandBox implements SubBrandRepository {
  late final Box<SubBrandModel> _box;

  /// Constructor requires a [Store] to initialize the sub-brand box.
  SubBrandBox(Store store) {
    _box = store.box<SubBrandModel>();
  }

  @override
  Stream<List<SubBrand>> getSubBrandsStream() {
    final query = _box
        .query()
        .order(SubBrandModel_.name)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find().map((e) => e.toEntity()).toList());
  }

  @override
  Future<List<SubBrand>> getAllSubBrands() async {
    final subBrands = _box.getAll();
    subBrands.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return subBrands.map((e) => e.toEntity()).toList();
  }

  @override
  Future<SubBrand?> getSubBrandById(int id) async {
    return _box.get(id)?.toEntity();
  }

  @override
  Future<int> addSubBrand(SubBrand subBrand) async {
    return _box.put(SubBrandModel.fromEntity(subBrand));
  }

  @override
  Future<void> updateSubBrand(SubBrand subBrand) async {
    _box.put(SubBrandModel.fromEntity(subBrand));
  }

  @override
  Future<bool> deleteSubBrand(int id) async {
    return _box.remove(id);
  }

  @override
  Future<List<SubBrand>> getSubBrandsForBrand(int brandId) async {
    final query =
        _box.query(SubBrandModel_.brand.equals(brandId)).build();
    final subBrands = query.find();
    subBrands.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    query.close();
    return subBrands.map((e) => e.toEntity()).toList();
  }
}
