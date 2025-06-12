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
  Future<List<ProductVariant>> searchVariants(String searchTerm, {int? brandId});
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

  @override
  Future<List<ProductVariant>> searchVariants(String searchTerm, {int? brandId}) async {
    final lowerSearchTerm = searchTerm.toLowerCase();
    
    QueryBuilder<ProductVariant> queryBuilder = _variantBox.query();
    Condition<ProductVariant>? searchCondition;
    Condition<ProductVariant>? brandCondition;

    if (lowerSearchTerm.isNotEmpty) {
      searchCondition = ProductVariant_.name.contains(lowerSearchTerm, caseSensitive: false)
          .or(ProductVariant_.baseProductName.contains(lowerSearchTerm, caseSensitive: false));
          // Add other searchable fields to the `or` condition as needed
          // e.g., .or(ProductVariant_.flavor.contains(lowerSearchTerm, caseSensitive: false))
    }

    if (brandId != null) {
      brandCondition = ProductVariant_.brand.equals(brandId);
    }

    if (searchCondition != null && brandCondition != null) {
      queryBuilder = _variantBox.query(searchCondition.and(brandCondition));
    } else if (searchCondition != null) {
      queryBuilder = _variantBox.query(searchCondition);
    } else if (brandCondition != null) {
      queryBuilder = _variantBox.query(brandCondition);
    }
    // If both are null, it queries all, which is equivalent to getAllProductVariants.

    final query = queryBuilder.order(ProductVariant_.name).build();
    final variants = query.find();
    // Sorting is now handled by the query order, but can be adjusted if needed.
    // variants.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return variants;
  }
}
