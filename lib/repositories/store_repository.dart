// Import necessary libraries for asynchronous operations and data models.
import 'dart:async';
import '../models/models.dart'; // Barrel file that exports all data models.
import '../objectbox_helper.dart';   // Helper class for ObjectBox database interactions.
import '../objectbox.g.dart'; // Generated file containing ObjectBox query conditions and entity info.

/// Abstract interface for the Store Repository.
///
/// This defines a contract for all data operations related to [GroceryStore] entities.
/// Using an interface is a best practice that allows for dependency injection and makes

/// the application more testable by enabling mock implementations.
/// MARK: ABSTRACT
abstract class IStoreRepository {
  /// Retrieves a reactive stream of all grocery stores.
  ///
  /// The stream will automatically emit a new list of [GroceryStore] objects
  /// whenever there is a change in the underlying data (e.g., a store is added,
  /// updated, or deleted).
  Stream<List<GroceryStore>> getStoresStream();

  /// Retrieves a one-time list of all grocery stores.
  ///
  /// This method returns a [Future] that completes with a list of all stores
  /// at the time of the call. It does not update automatically.
  Future<List<GroceryStore>> getAllStores();

  /// Retrieves a single grocery store by its unique ID.
  ///
  /// Returns a [Future] that completes with the [GroceryStore] object if found,
  /// otherwise completes with `null`.
  Future<GroceryStore?> getStoreById(int id);

  /// Adds a new grocery store to the database.
  ///
  /// Takes a [GroceryStore] object and persists it.
  /// Returns a [Future] that completes with the ID assigned to the new store.
  Future<int> addStore(GroceryStore store);

  /// Updates an existing grocery store in the database.
  ///
  /// Takes a [GroceryStore] object that must have a valid ID.
  Future<void> updateStore(GroceryStore store);

  /// Deletes a grocery store from the database by its ID.
  ///
  /// Returns a [Future] that completes with `true` if the deletion was successful,
  /// and `false` otherwise.
  Future<bool> deleteStore(int id);

  /// Retrieves a list of stores that have a price entry for a product variant
  /// with a matching base product name or variant name.
  ///
  /// Takes a [productName] (which can be a base product name or a variant name)
  /// and returns a [Future] that completes with a list of [GroceryStore] objects
  /// that have at least one [PriceEntry] linked to a [ProductVariant]
  /// whose `baseProductName` or `name` matches the input.
  Future<List<GroceryStore>> getStoresWithPriceEntryForProduct(String productName);
}

/// Concrete implementation of [IStoreRepository] using the ObjectBox database.
///
/// This class handles the actual data storage and retrieval logic for [GroceryStore] entities.
/// MARK: OBJECTBOX
class StoreRepository implements IStoreRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<GroceryStore> _storeBox;

  /// Constructor for the repository.
  ///
  /// It requires an instance of [ObjectBoxHelper] to get access to the database store.
  /// It initializes the [_storeBox], which is the specific "table" for [GroceryStore] objects.
  StoreRepository(this._objectBoxHelper) {
    _storeBox = _objectBoxHelper.groceryStoreBox;
  }

  /// Provides a stream of all stores, ordered alphabetically by name.
  @override
  Stream<List<GroceryStore>> getStoresStream() {
    // 1. Create a query for all GroceryStore objects.
    // 2. Order the results by the 'name' property.
    // 3. Use `watch()` to create a stream that emits new results on changes.
    //    `triggerImmediately: true` ensures the stream sends the current data right away.
    final query = _storeBox.query().order(GroceryStore_.name).watch(triggerImmediately: true);
    // 4. Map the stream of Query<GroceryStore> objects to a stream of List<GroceryStore>.
    return query.map((query) => query.find());
  }

  /// Fetches all stores at once and returns them as a sorted list.
   @override
  Future<List<GroceryStore>> getAllStores() async {
    // `getAll()` retrieves all objects from the box.
    final stores = _storeBox.getAll();
    // Manually sort the list alphabetically by name (case-insensitive).
    stores.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return stores;
  }

  /// Retrieves a single store by its unique ID from the box.
  @override
  Future<GroceryStore?> getStoreById(int id) async {
    // `get()` is the most efficient way to retrieve a single object by its ID.
    return _storeBox.get(id);
  }

  /// Adds a new store to the box.
  @override
  Future<int> addStore(GroceryStore store) async {
    // `put()` inserts a new object and returns the ID assigned to it by ObjectBox.
    return _storeBox.put(store);
  }

  /// Updates an an existing store in the box.
  @override
  Future<void> updateStore(GroceryStore store) async {
     // If the 'id' property of the `store` object is set and exists in the box,
     // `put()` will update the existing object instead of creating a new one.
     _storeBox.put(store);
  }

  /// Deletes a store from the box by its ID.
  @override
  Future<bool> deleteStore(int id) async {
    // `remove()` deletes the object with the specified ID.
    // It returns `true` if an object was found and removed, `false` otherwise.
    return _storeBox.remove(id);
  }

  /// Retrieves a list of stores that have a price entry for a product variant
  /// with a matching base product name or variant name.
  ///
  /// This implementation is more efficient than fetching all stores and filtering
  /// in memory. It uses queries to filter at the database level.
  @override
  Future<List<GroceryStore>> getStoresWithPriceEntryForProduct(String productName) async {
    // 1. Find all product variants that match the given name (case-insensitive).
    final productVariantBox = _objectBoxHelper.productVariantBox;
    final matchingVariantsQuery = productVariantBox.query(
      ProductVariant_.name.equals(productName, caseSensitive: false)
      .or(ProductVariant_.baseProductName.equals(productName, caseSensitive: false))
    );
    final matchingVariantIds = matchingVariantsQuery.build().findIds();

    // If no variants match, no stores will have price entries for them.
    if (matchingVariantIds.isEmpty) {
      return [];
    }

    // 2. Find all price entries linked to these matching variants.
    final priceEntryBox = _objectBoxHelper.priceEntryBox;
    final priceEntriesQuery = priceEntryBox.query(
      PriceEntry_.productVariant.oneOf(matchingVariantIds)
    );
    final priceEntries = priceEntriesQuery.build().find();

    // If no price entries exist for these variants, no stores are linked.
    if (priceEntries.isEmpty) {
      return [];
    }

    // 3. Get the unique store IDs from these price entries.
    // Using a Set ensures that each store ID is listed only once.
    final storeIds = priceEntries.map((pe) => pe.groceryStore.targetId).toSet();
    
    // Remove any invalid store IDs (targetId is 0 if not set).
    storeIds.removeWhere((id) => id == 0);

    // 4. Fetch the store objects by their unique IDs.
    final storesWithNulls = _storeBox.getMany(storeIds.toList());
    
    // Filter out any nulls before sorting
    final stores = storesWithNulls.whereType<GroceryStore>().toList();

    // Sort the final list of stores alphabetically by name.
    stores.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    return stores;
  }
}
