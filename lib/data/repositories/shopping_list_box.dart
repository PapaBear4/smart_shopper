import 'package:smart_shopper/data/models/shopping_list_model.dart';
import 'package:smart_shopper/domain/entities/shopping_list.dart';
import 'package:smart_shopper/domain/repositories/shopping_list_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

class ShoppingListBox implements ShoppingListRepository {
  final Box<ShoppingListModel> _box;

  ShoppingListBox(Store store) : _box = store.box<ShoppingListModel>();

  @override
  Future<void> delete(int id) async => _box.remove(id);

  @override
  Future<List<ShoppingList>> getAll() async =>
      _box.getAll().map((e) => e.toEntity()).toList();

  @override
  Future<ShoppingList?> getById(int id) async => _box.get(id)?.toEntity();

  @override
  Future<void> save(ShoppingList list) async {
    final model = ShoppingListModel.fromEntity(list);
    // TODO: Handle relationships
    _box.put(model);
  }

  @override
  Stream<List<ShoppingList>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) =>
        query.find().map((e) => e.toEntity()).toList());
  }
}
