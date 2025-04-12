import 'dart:developer';

import 'package:smart_shopper/objectbox.g.dart';

import '../models/models.dart'; // Uses the barrel file
import '../objectbox.dart';   // The ObjectBox helper class

// Define an interface (abstract class) for testability/mocking
abstract class IShoppingListRepository {
  Stream<List<ShoppingList>> getAllListsStream(); // Get lists reactively
  Future<int> addList(ShoppingList list);
  Future<bool> deleteList(int id);
  Future<void> updateList(ShoppingList list); // For renaming
}

// Concrete implementation using ObjectBox
class ShoppingListRepository implements IShoppingListRepository {
  final ObjectBox _objectBox;
  late final Box<ShoppingList> _listBox;

  ShoppingListRepository(this._objectBox) {
    _listBox = _objectBox.shoppingListBox; // Get the box from the helper
  }

  @override
  Stream<List<ShoppingList>> getAllListsStream() {
    // Create a query for all ShoppingList objects, sorted by name
    final query = _listBox.query().order(ShoppingList_.name).watch(triggerImmediately: true);
    // Map the query stream to a stream of lists
    return query.map((query) => query.find());
  }

  @override
  Future<int> addList(ShoppingList list) async {
    log("Repository: addList called for '${list.name}'"); // <-- ADD THIS
    try {
      final id = _listBox.put(list);
      log("Repository: ObjectBox put successful, ID: $id"); // <-- ADD THIS
      return id;
    } catch (e) {
      log("Repository: ERROR calling put: $e"); // <-- ADD THIS
      rethrow; // Re-throw the error so the Cubit can catch it
    }
  }

  @override
  Future<bool> deleteList(int id) async {
    // remove() returns true if an object was removed
    return _listBox.remove(id);
  }

  @override
  Future<void> updateList(ShoppingList list) async {
    // put() also updates if the object ID already exists
    _listBox.put(list);
  }
}