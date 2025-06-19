import 'dart:async';
import '../models/brand.dart';
import '../objectbox_helper.dart';
import '../objectbox.g.dart';

abstract class ISubBrandRepository {
  Stream<List<SubBrand>> getSubBrandsStream();
  Future<List<SubBrand>> getAllSubBrands();
  Future<SubBrand?> getSubBrandById(int id);
  Future<int> addSubBrand(SubBrand subBrand);
  Future<void> updateSubBrand(SubBrand subBrand);
  Future<bool> deleteSubBrand(int id);
  Future<List<SubBrand>> getSubBrandsForBrand(int brandId);
}

class SubBrandRepository implements ISubBrandRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<SubBrand> _subBrandBox;

  SubBrandRepository(this._objectBoxHelper) {
    _subBrandBox = _objectBoxHelper.subBrandBox;
  }

  @override
  Stream<List<SubBrand>> getSubBrandsStream() {
    final query = _subBrandBox.query().order(SubBrand_.name).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<SubBrand>> getAllSubBrands() async {
    final subBrands = _subBrandBox.getAll();
    subBrands.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return subBrands;
  }

  @override
  Future<SubBrand?> getSubBrandById(int id) async {
    return _subBrandBox.get(id);
  }

  @override
  Future<int> addSubBrand(SubBrand subBrand) async {
    return _subBrandBox.put(subBrand);
  }

  @override
  Future<void> updateSubBrand(SubBrand subBrand) async {
    _subBrandBox.put(subBrand);
  }

  @override
  Future<bool> deleteSubBrand(int id) async {
    return _subBrandBox.remove(id);
  }

  @override
  Future<List<SubBrand>> getSubBrandsForBrand(int brandId) async {
    final query = _subBrandBox.query(SubBrand_.brand.equals(brandId)).build();
    return query.find();
  }
}
