import 'package:smart_shopper/domain/entities/shopping_list.dart';

/// Repository for managing shopping lists.
abstract class ShoppingListRepository {
  /// Retrieves all shopping lists.
  Future<List<ShoppingList>> getAll();

  /// Retrieves a single shopping list by its ID.
  Future<ShoppingList?> getById(int id);

  /// Saves a shopping list (creates if new, updates if exists).
  Future<void> save(ShoppingList list);

  /// Deletes a shopping list by its ID.
  Future<void> delete(int id);

  /// Watches for changes to all shopping lists.
  Stream<List<ShoppingList>> watchAll();
}
