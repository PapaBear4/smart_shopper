import 'dart:async';
import '../entities/sub_brand.dart';

/// Defines the interface for sub-brand data operations.
abstract class SubBrandRepository {
  /// Returns a stream of all sub-brands.
  Stream<List<SubBrand>> getSubBrandsStream();

  /// Gets all sub-brands.
  Future<List<SubBrand>> getAllSubBrands();

  /// Gets a single sub-brand by its ID.
  Future<SubBrand?> getSubBrandById(int id);

  /// Adds a new sub-brand.
  Future<int> addSubBrand(SubBrand subBrand);

  /// Updates an existing sub-brand.
  Future<void> updateSubBrand(SubBrand subBrand);

  /// Deletes a sub-brand by its ID.
  Future<bool> deleteSubBrand(int id);

  /// Gets all sub-brands for a given brand ID.
  Future<List<SubBrand>> getSubBrandsForBrand(int brandId);
}
