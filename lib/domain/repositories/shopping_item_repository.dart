import 'package:smart_shopper/domain/entities/shopping_item.dart';

/// Repository for managing shopping items.
abstract class ShoppingItemRepository {
  /// Retrieves all shopping items.
  Future<List<ShoppingItem>> getAll();

  /// Retrieves a single shopping item by its ID.
  Future<ShoppingItem?> getById(int id);

  /// Saves a shopping item (creates if new, updates if exists).
  /// Requires the ID of the parent [ShoppingList].
  Future<void> save(ShoppingItem item, int shoppingListId);

  /// Deletes a shopping item by its ID.
  Future<void> delete(int id);

  /// Watches for changes to all shopping items.
  Stream<List<ShoppingItem>> watchAll();
}
