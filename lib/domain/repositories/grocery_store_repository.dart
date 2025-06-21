import 'package:smart_shopper/domain/entities/grocery_store.dart';

abstract class GroceryStoreRepository {
  Future<List<GroceryStore>> getAll();
  Future<GroceryStore?> getById(int id);
  Future<void> save(GroceryStore store);
  Future<void> delete(int id);
}
