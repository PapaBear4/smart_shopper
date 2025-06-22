import 'package:smart_shopper/data/models/shopping_item_model.dart';
import 'package:smart_shopper/data/models/shopping_list_model.dart';
import 'package:smart_shopper/domain/entities/shopping_item.dart';
import 'package:smart_shopper/domain/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

class ShoppingItemBox implements ShoppingItemRepository {
  final Box<ShoppingItemModel> _box;
  final Box<ShoppingListModel> _listBox;

  ShoppingItemBox(Store store)
      : _box = store.box<ShoppingItemModel>(),
        _listBox = store.box<ShoppingListModel>();

  @override
  Future<void> delete(int id) async => _box.remove(id);

  @override
  Future<List<ShoppingItem>> getAll() async =>
      _box.getAll().map((e) => e.toEntity()).toList();

  @override
  Future<ShoppingItem?> getById(int id) async => _box.get(id)?.toEntity();

  @override
  Future<void> save(ShoppingItem item, int shoppingListId) async {
    final model = ShoppingItemModel.fromEntity(item);
    final list = _listBox.get(shoppingListId);
    if (list != null) {
      model.shoppingList.target = list;
    }
    // TODO: Handle other relationships
    _box.put(model);
  }

  @override
  Stream<List<ShoppingItem>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) =>
        query.find().map((e) => e.toEntity()).toList());
  }
}
