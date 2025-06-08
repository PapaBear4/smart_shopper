import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart'; // Changed from objectbox.dart
import '../objectbox.g.dart'; // Required for generated query conditions like ShoppingItem_.shoppingList

// Interface definition
abstract class IShoppingItemRepository {
  Stream<List<ShoppingItem>> getItemsStream(int listId);
  Future<int> addItem(ShoppingItem item, int listId);
  Future<void> updateItem(ShoppingItem item);
  Future<bool> deleteItem(int id);
  Future<ShoppingList?> getShoppingList(
    int listId,
  ); // Helper to get list details
}

// Implementation using ObjectBox
class ShoppingItemRepository implements IShoppingItemRepository {
  final ObjectBoxHelper _objectBoxHelper; // Changed type
  late final Box<ShoppingItem> _itemBox;
  late final Box<ShoppingList> _listBox; // Needed to fetch list details

  ShoppingItemRepository(this._objectBoxHelper) { // Changed parameter type
    _itemBox = _objectBoxHelper.shoppingItemBox; // Changed to use helper
    _listBox = _objectBoxHelper.shoppingListBox; // Changed to use helper
  }

  @override
  Stream<List<ShoppingItem>> getItemsStream(int listId) {
    // Query for items where the 'shoppingList' relation targets the given listId
    final builder = _itemBox.query(ShoppingItem_.shoppingList.equals(listId));

    // Watch the query for changes, triggering immediately
    final queryStream = builder.watch(triggerImmediately: true);

    // Map the stream of queries to a stream of lists of items
    // Also apply sorting here: unchecked first, then by name
    return queryStream.map((query) {
      // Find the items for the current query result
      final items = query.find();

      // Sort the list IN PLACE using a custom comparison function
      items.sort((a, b) {
        // Manually compare boolean 'isCompleted' status
        int completedCompare;
        if (a.isCompleted == b.isCompleted) {
          completedCompare = 0; // Both are same (both true or both false)
        } else if (a.isCompleted) {
          // 'a' is true (completed), 'b' is false (incomplete)
          // Completed items should come AFTER incomplete ones.
          completedCompare = 1; // a > b
        } else {
          // 'a' is false (incomplete), 'b' is true (completed)
          // Incomplete items should come BEFORE completed ones.
          completedCompare = -1; // a < b
        }

        // If completion status is different, return that result
        if (completedCompare != 0) {
          return completedCompare;
        } else {
          // Otherwise (if completion status is the same), sort by name
          // String DOES have compareTo, so this part is correct.
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
      });

      // Return the now-sorted list
      return items;
    });
  }

  @override
  Future<int> addItem(ShoppingItem item, int listId) async {
    item.shoppingList.targetId = listId;
    try {
      final id = _itemBox.put(item);
      return id;
    } catch (e) {
      // Capture stack trace (s)
      rethrow;
    }
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    // Put handles both inserts and updates based on the ID.
    // Ensure item.id is correctly set before calling update.
    // Any changes to the item's fields (name, quantity, isCompleted)
    // or its ToMany<GroceryStore> link will be persisted.
    _itemBox.put(item);
  }

  @override
  Future<bool> deleteItem(int id) async {
    // remove() returns true if an object with the given ID was found and removed.
    return _itemBox.remove(id);
    // Note: This doesn't automatically handle cleanup in related objects unless
    // specifically designed for (e.g., removing item ID from a list elsewhere).
    // For ObjectBox relations, simply removing the item is usually sufficient.
  }

  // Helper method to get the parent shopping list details if needed (e.g., for AppBar title)
  @override
  Future<ShoppingList?> getShoppingList(int listId) async {
    return _listBox.get(listId);
  }
}
