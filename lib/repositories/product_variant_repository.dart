import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart';
import '../objectbox.g.dart';

abstract class IProductVariantRepository {
  Stream<List<ProductVariant>> getProductVariantsStream();
  Future<List<ProductVariant>> getAllProductVariants();
  Future<ProductVariant?> getProductVariantById(int id);
  Future<int> addProductVariant(ProductVariant variant);
  Future<void> updateProductVariant(ProductVariant variant);
  Future<bool> deleteProductVariant(int id);
  Future<List<ProductVariant>> findVariantsByBaseName(String baseProductName);
  Future<List<ProductVariant>> findVariantsByBrand(int brandId);
}

class ProductVariantRepository implements IProductVariantRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<ProductVariant> _variantBox;

  ProductVariantRepository(this._objectBoxHelper) {
    _variantBox = _objectBoxHelper.productVariantBox;
  }

  @override
  Stream<List<ProductVariant>> getProductVariantsStream() {
    final query = _variantBox.query().order(ProductVariant_.baseProductName).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<ProductVariant>> getAllProductVariants() async {
    final variants = _variantBox.getAll();
    variants.sort((a, b) => a.baseProductName.toLowerCase().compareTo(b.baseProductName.toLowerCase()));
    return variants;
  }

  @override
  Future<ProductVariant?> getProductVariantById(int id) async {
    return _variantBox.get(id);
  }

  @override
  Future<int> addProductVariant(ProductVariant variant) async {
    return _variantBox.put(variant);
  }

  @override
  Future<void> updateProductVariant(ProductVariant variant) async {
    _variantBox.put(variant);
  }

  @override
  Future<bool> deleteProductVariant(int id) async {
    return _variantBox.remove(id);
  }

  @override
  Future<List<ProductVariant>> findVariantsByBaseName(String baseProductName) async {
    final query = _variantBox.query(ProductVariant_.baseProductName.equals(baseProductName)).build();
    return query.find();
  }

  @override
  Future<List<ProductVariant>> findVariantsByBrand(int brandId) async {
    final query = _variantBox.query(ProductVariant_.brand.equals(brandId)).build();
    return query.find();
  }
}
