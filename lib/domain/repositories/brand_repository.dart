/// This file defines the repository for managing `Brand` data.
///
/// It includes the abstract interface `IBrandRepository` and its concrete
/// implementation `BrandRepository` which uses ObjectBox for data persistence.
/// This approach allows for decoupling the data layer from the UI and business logic,
/// making the app more modular and testable.
import 'dart:async';
import '../entities/brand.dart';

/// Abstract interface for a repository that manages brand data.
///
/// This interface defines the contract for brand-related data operations.
/// Using an interface allows for multiple implementations (e.g., for production,
/// testing, or different database backends) and promotes loose coupling.
abstract class BrandRepository {
  /// Returns a stream of all brands, sorted by name.
  ///
  /// The stream emits a new list of brands whenever the data changes in the database.
  /// This is useful for building reactive UI components that update automatically.
  Stream<List<Brand>> getBrandsStream();

  /// Fetches a list of all brands from the database once.
  ///
  /// This method provides a snapshot of the current state of all brands.
  Future<List<Brand>> getAllBrands();

  /// Fetches a single brand by its unique ID.
  ///
  /// Returns `null` if no brand with the given [id] is found.
  Future<Brand?> getBrandById(int id); // Added method

  /// Adds a new [brand] to the database.
  ///
  /// Returns the ID assigned to the new brand by the database.
  Future<int> addBrand(Brand brand);

  /// Updates an existing [brand] in the database.
  ///
  /// The brand to be updated is identified by its `id` property.
  Future<void> updateBrand(Brand brand);

  /// Deletes a brand from the database by its unique [id].
  ///
  /// Returns `true` if the deletion was successful, `false` otherwise.
  Future<bool> deleteBrand(int id);
  // Future<void> addBrandToStore(int brandId, int storeId); // Example if needed
  // Future<void> removeBrandFromStore(int brandId, int storeId); // Example if needed

  // Note: These methods are part of the interface to ensure that any implementation
  // of the brand repository acknowledges the relationship with SubBrand and ProductLine.
  // However, the actual implementation logic belongs in their respective repositories
  // to maintain separation of concerns.
}
