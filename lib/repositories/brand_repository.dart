import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart'; // Changed from objectbox.dart
import '../objectbox.g.dart';

abstract class IBrandRepository {
  Stream<List<Brand>> getBrandsStream();
  Future<List<Brand>> getAllBrands();
  Future<int> addBrand(Brand brand);
  Future<void> updateBrand(Brand brand);
  Future<bool> deleteBrand(int id);
  // Future<void> addBrandToStore(int brandId, int storeId); // Example if needed
  // Future<void> removeBrandFromStore(int brandId, int storeId); // Example if needed
}

class BrandRepository implements IBrandRepository {
  final ObjectBoxHelper _objectBoxHelper; // Changed type
  late final Box<Brand> _brandBox;

  BrandRepository(this._objectBoxHelper) { // Changed parameter type
    _brandBox = _objectBoxHelper.brandBox; // Changed to use helper
  }

  @override
  Stream<List<Brand>> getBrandsStream() {
    final query = _brandBox.query().order(Brand_.name).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<Brand>> getAllBrands() async {
    final brands = _brandBox.getAll();
    brands.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return brands;
  }

  @override
  Future<int> addBrand(Brand brand) async {
    return _brandBox.put(brand);
  }

  @override
  Future<void> updateBrand(Brand brand) async {
    _brandBox.put(brand);
  }

  @override
  Future<bool> deleteBrand(int id) async {
    return _brandBox.remove(id);
  }
}
