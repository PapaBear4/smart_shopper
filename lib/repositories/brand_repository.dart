/// This file defines the repository for managing `Brand` data.
///
/// It includes the abstract interface `IBrandRepository` and its concrete
/// implementation `BrandRepository` which uses ObjectBox for data persistence.
/// This approach allows for decoupling the data layer from the UI and business logic,
/// making the app more modular and testable.
import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart'; // Changed from objectbox.dart
import '../objectbox.g.dart';

/// Abstract interface for a repository that manages brand data.
///
/// This interface defines the contract for brand-related data operations.
/// Using an interface allows for multiple implementations (e.g., for production,
/// testing, or different database backends) and promotes loose coupling.
/// MARK: ABSTRACT
abstract class IBrandRepository {
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

// MARK: OBJECTBOX
/// Concrete implementation of [IBrandRepository] using ObjectBox.
///
/// This class handles the actual database operations for `Brand` entities.
class BrandRepository implements IBrandRepository {
  /// A helper class that provides access to the ObjectBox store and boxes.
  final ObjectBoxHelper _objectBoxHelper; // Changed type
  /// The ObjectBox Box specifically for storing and retrieving `Brand` objects.
  late final Box<Brand> _brandBox;

  /// Creates an instance of [BrandRepository].
  ///
  /// Requires an [ObjectBoxHelper] to interact with the database.
  BrandRepository(this._objectBoxHelper) {
    _brandBox = _objectBoxHelper.brandBox;
  }

  @override
  Stream<List<Brand>> getBrandsStream() {
    // Creates a query that retrieves all Brand objects, ordered by their 'name' field.
    // .watch() turns this into a stream that automatically emits a new list
    // when the underlying data changes. `triggerImmediately: true` ensures that
    // the stream emits the current data as soon as a listener subscribes.
    final query = _brandBox
        .query()
        .order(Brand_.name)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<Brand>> getAllBrands() async {
    // Retrieves all Brand objects from the box.
    final brands = _brandBox.getAll();
    // Sorts the list in-place alphabetically by name (case-insensitive).
    brands.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return brands;
  }

  @override
  Future<Brand?> getBrandById(int id) async {
    // Retrieves a single Brand object by its ID.
    // Returns null if no object with the given ID exists.
    return _brandBox.get(id);
  }

  @override
  Future<int> addBrand(Brand brand) async {
    // Adds or updates a Brand object. If the brand's ID is 0, a new object
    // is inserted and a new ID is generated. If the ID is non-zero, the
    // existing object with that ID is updated.
    // Returns the ID of the put object.
    return _brandBox.put(brand);
  }

  @override
  Future<void> updateBrand(Brand brand) async {
    // This is an alias for `addBrand`. The `put` method handles both
    // creation and updating. This method is provided for semantic clarity.
    _brandBox.put(brand);
  }

  @override
  Future<bool> deleteBrand(int id) async {
    // Removes the Brand object with the specified ID from the box.
    // Returns true if an object was successfully removed, false otherwise.
    return _brandBox.remove(id);
  }
}
