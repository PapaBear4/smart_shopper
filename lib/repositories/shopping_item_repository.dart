// Import necessary async library for Stream support.
import 'dart:async';

// Import the data models used by this repository.
import '../models/models.dart';

// Import the ObjectBox helper for database interaction.
import '../objectbox_helper.dart'; 

// Import the generated ObjectBox file for query builders and conditions.
import '../objectbox.g.dart'; 

/// Abstract interface for a shopping item repository.
/// It defines the contract for managing ShoppingItem entities,
/// decoupling the application logic from the specific database implementation.
abstract class IShoppingItemRepository {
  /// Retrieves a stream of shopping items for a specific shopping list.
  /// The stream updates automatically when items in the list change.
  /// [listId]: The ID of the shopping list whose items are to be fetched.
  Stream<List<ShoppingItem>> getItemsStream(int listId);

  /// Adds a new shopping item to a specific shopping list.
  /// [item]: The ShoppingItem object to add.
  /// [listId]: The ID of the shopping list to which the item should be added.
  /// Returns the ID of the newly created item.
  Future<int> addItem(ShoppingItem item, int listId);

  /// Updates an existing shopping item.
  /// [item]: The shopping item with updated information.
  Future<void> updateItem(ShoppingItem item);

  /// Deletes a shopping item by its ID.
  /// [id]: The unique ID of the item to delete.
  /// Returns true if the deletion was successful, false otherwise.
  Future<bool> deleteItem(int id);

  /// Retrieves the parent ShoppingList object.
  /// This can be useful for displaying list details, like its name.
  /// [listId]: The ID of the shopping list to retrieve.
  Future<ShoppingList?> getShoppingList(int listId);

  /// Updates a list of shopping items in a single batch operation.
  /// [items]: The list of ShoppingItem objects to update.
  Future<void> updateItems(List<ShoppingItem> items);

  /// Retrieves a stream of shopping items filtered by a specific store.
  /// This is used to see all items that can be purchased at a given store.
  /// [storeId]: The ID of the store to filter by.
  Stream<List<ShoppingItem>> getItemsForStoreStream(int storeId);
}

/// Concrete implementation of [IShoppingItemRepository] using ObjectBox.
/// This class handles all the database operations for ShoppingItem entities.
class ShoppingItemRepository implements IShoppingItemRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<ShoppingItem> _itemBox;
  late final Box<ShoppingList> _listBox;

  /// Constructor that takes an [ObjectBoxHelper] instance.
  /// Initializes the necessary ObjectBox 'boxes' for items and lists.
  ShoppingItemRepository(this._objectBoxHelper) {
    _itemBox = _objectBoxHelper.shoppingItemBox;
    _listBox = _objectBoxHelper.shoppingListBox;
  }

  /// Provides a stream of items for a given shopping list, sorted with incomplete items first.
  @override
  Stream<List<ShoppingItem>> getItemsStream(int listId) {
    // Create a query for ShoppingItems where the 'shoppingList' relation points to the given listId.
    final builder = _itemBox.query(ShoppingItem_.shoppingList.equals(listId));

    // Watch the query for changes. `triggerImmediately: true` ensures the stream emits the current data right away.
    final queryStream = builder.watch(triggerImmediately: true);

    // Map the stream of Query<ShoppingItem> to a stream of List<ShoppingItem>.
    return queryStream.map((query) {
      // Execute the query to get the current list of items.
      final items = query.find();

      // Sort the list of items in place.
      items.sort((a, b) {
        // First, compare by completion status.
        int completedCompare;
        if (a.isCompleted == b.isCompleted) {
          completedCompare = 0; // Both are the same.
        } else if (a.isCompleted) {
          // 'a' is completed, 'b' is not. Completed items go to the bottom.
          completedCompare = 1; 
        } else {
          // 'a' is incomplete, 'b' is completed. Incomplete items go to the top.
          completedCompare = -1;
        }

        // If completion status is different, sort by it.
        if (completedCompare != 0) {
          return completedCompare;
        } else {
          // If completion status is the same, sort alphabetically by name.
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
      });

      return items;
    });
  }

  /// Provides a stream of items available at a specific store, sorted with incomplete items first.
  @override
  Stream<List<ShoppingItem>> getItemsForStoreStream(int storeId) {
    final queryBuilder = _itemBox.query();
    // Link from ShoppingItem to GroceryStore via the 'groceryStores' relation
    // and filter for items linked to the specified storeId.
    queryBuilder.linkMany(ShoppingItem_.groceryStores, GroceryStore_.id.equals(storeId));

    final queryStream = queryBuilder.watch(triggerImmediately: true);

    return queryStream.map((query) {
      final items = query.find();
      
      // Sort items using the same logic as in getItemsStream: incomplete first, then by name.
      items.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return a.isCompleted ? 1 : -1;
      });
      return items;
    });
  }
  
  /// Adds a new item to the database and associates it with a shopping list.
  @override
  Future<int> addItem(ShoppingItem item, int listId) async {
    // Set the target ID for the ToOne relationship to the shopping list.
    item.shoppingList.targetId = listId;
    // The `put` method inserts the new item and returns its assigned ID.
    final id = _itemBox.put(item);
    return id;
  }

  /// Updates an existing item in the database.
  @override
  Future<void> updateItem(ShoppingItem item) async {
    // The `put` method handles both inserts and updates. If the item's ID is set,
    // ObjectBox will update the existing record.
    _itemBox.put(item);
  }

  /// Deletes an item from the database.
  @override
  Future<bool> deleteItem(int id) async {
    // The `remove` method returns true if an object with the given ID was found and removed.
    return _itemBox.remove(id);
  }

  /// Retrieves details of the parent shopping list.
  @override
  Future<ShoppingList?> getShoppingList(int listId) async {
    // The `get` method retrieves a single object by its ID.
    return _listBox.get(listId);
  }

  /// Efficiently updates multiple items in the database.
  @override
  Future<void> updateItems(List<ShoppingItem> items) async {
    // `putMany` is more efficient for batch operations than calling `put` in a loop.
    _itemBox.putMany(items);
  }
}
