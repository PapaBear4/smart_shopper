import 'dart:async';
import '../entities/brand.dart';

/// Defines the interface for brand data operations.
abstract class BrandRepository {
  /// Returns a stream of all brands, ordered by name.
  Stream<List<Brand>> getBrandsStream();

  /// Returns a list of all brands.
  Future<List<Brand>> getAllBrands();

  /// Retrieves a single brand by its ID.
  Future<Brand?> getBrandById(int id);

  /// Adds a new brand to the database and returns its ID.
  Future<int> addBrand(Brand brand);

  /// Updates an existing brand.
  Future<void> updateBrand(Brand brand);

  /// Deletes a brand by its ID and returns true if successful.
  Future<bool> deleteBrand(int id);
}
