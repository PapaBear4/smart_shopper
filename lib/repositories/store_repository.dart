import 'dart:async';
import '../models/models.dart'; // Barrel file for models
import '../objectbox.dart';   // ObjectBox helper
import '../objectbox.g.dart'; // Generated file for query conditions

// Interface for the Store Repository
abstract class IStoreRepository {
  Stream<List<GroceryStore>> getStoresStream(); // Reactive stream of stores
  Future<List<GroceryStore>> getAllStores();   // One-time fetch of all stores
  Future<int> addStore(GroceryStore store);
  Future<void> updateStore(GroceryStore store);
  Future<bool> deleteStore(int id);
}

// Implementation using ObjectBox
class StoreRepository implements IStoreRepository {
  final ObjectBox _objectBox;
  late final Box<GroceryStore> _storeBox;

  StoreRepository(this._objectBox) {
    // Get the GroceryStore box from the ObjectBox instance
    _storeBox = _objectBox.groceryStoreBox; // Assumes groceryStoreBox exists in ObjectBox helper [cite: uploaded:lib/objectbox.dart]
  }

  @override
  Stream<List<GroceryStore>> getStoresStream() {
    // Query all stores, order by name, watch for changes
    final query = _storeBox.query().order(GroceryStore_.name).watch(triggerImmediately: true); // [cite: uploaded:lib/objectbox.g.dart]
    // Map the stream of queries to a stream of results (List<GroceryStore>)
    return query.map((query) => query.find());
  }

   @override
  Future<List<GroceryStore>> getAllStores() async {
    // Fetch all stores at once and sort them by name
    final stores = _storeBox.getAll();
    stores.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return stores;
  }

  @override
  Future<int> addStore(GroceryStore store) async {
    // Add a new store, put returns the assigned ID
    return _storeBox.put(store);
  }

  @override
  Future<void> updateStore(GroceryStore store) async {
    // Update an existing store (identified by store.id)
     _storeBox.put(store);
  }

  @override
  Future<bool> deleteStore(int id) async {
    // Remove the store by its ID, returns true if successful
    return _storeBox.remove(id);
  }
}