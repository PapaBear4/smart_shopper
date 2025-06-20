import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart';
import '../objectbox.g.dart';

/// Defines the interface for sub-brand data operations.
/// This abstraction is key for a clean architecture, enabling features like
/// dependency injection and easier unit testing with mock repositories.
abstract class ISubBrandRepository {
  /// Returns a stream of all sub-brands, sorted by name.
  /// The stream automatically emits new data when changes occur in the database.
  Stream<List<SubBrand>> getSubBrandsStream();

  /// Fetches all sub-brands from the database in a single, non-reactive call.
  Future<List<SubBrand>> getAllSubBrands();

  /// Fetches a single sub-brand by its unique ID.
  /// Returns null if no sub-brand with the given ID is found.
  Future<SubBrand?> getSubBrandById(int id);

  /// Adds a new sub-brand to the database.
  /// Returns the ID of the newly created sub-brand.
  Future<int> addSubBrand(SubBrand subBrand);

  /// Updates an existing sub-brand in the database.
  Future<void> updateSubBrand(SubBrand subBrand);

  /// Deletes a sub-brand from the database by its ID.
  /// Returns true if the deletion was successful.
  Future<bool> deleteSubBrand(int id);

  /// Fetches all sub-brands associated with a specific brand ID.
  Future<List<SubBrand>> getSubBrandsForBrand(int brandId);
}

/// Concrete implementation of [ISubBrandRepository] using ObjectBox.
/// This class manages all CRUD operations for the [SubBrand] entity.
class SubBrandRepository implements ISubBrandRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<SubBrand> _subBrandBox;

  /// Constructor requires an [ObjectBoxHelper] to initialize the sub-brand box.
  SubBrandRepository(this._objectBoxHelper) {
    _subBrandBox = _objectBoxHelper.subBrandBox;
  }

  @override
  Stream<List<SubBrand>> getSubBrandsStream() {
    // Create a query for all SubBrand objects, ordered by name.
    // .watch() turns the query into a reactive stream.
    final query = _subBrandBox.query().order(SubBrand_.name).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<SubBrand>> getAllSubBrands() async {
    // .getAll() retrieves all objects from the box.
    final subBrands = _subBrandBox.getAll();
    // Sort the list alphabetically by name for consistent ordering.
    subBrands.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return subBrands;
  }

  @override
  Future<SubBrand?> getSubBrandById(int id) async {
    // .get() retrieves a single object by its ID.
    return _subBrandBox.get(id);
  }

  @override
  Future<int> addSubBrand(SubBrand subBrand) async {
    // .put() inserts or updates an object and returns its ID.
    return _subBrandBox.put(subBrand);
  }

  @override
  Future<void> updateSubBrand(SubBrand subBrand) async {
    // .put() is also used for updates.
    _subBrandBox.put(subBrand);
  }

  @override
  Future<bool> deleteSubBrand(int id) async {
    // .remove() deletes an object by its ID.
    return _subBrandBox.remove(id);
  }

  @override
  Future<List<SubBrand>> getSubBrandsForBrand(int brandId) async {
    // This query finds all SubBrand entities where the `brand` relation
    // points to the specified `brandId`.
    final query = _subBrandBox.query(SubBrand_.brand.equals(brandId)).build();
    final subBrands = query.find();
    // Sort the results for predictable ordering in the UI.
    subBrands.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    query.close(); // It's important to close queries to free up resources.
    return subBrands;
  }
}
