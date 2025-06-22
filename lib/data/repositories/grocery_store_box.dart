import 'package:smart_shopper/data/models/grocery_store_model.dart';
import 'package:smart_shopper/domain/entities/grocery_store.dart';
import 'package:smart_shopper/domain/repositories/grocery_store_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

class GroceryStoreBox implements GroceryStoreRepository {
  final Box<GroceryStoreModel> _box;

  GroceryStoreBox(Store store) : _box = store.box<GroceryStoreModel>();

  @override
  Future<void> delete(int id) async => _box.remove(id);

  @override
  Future<List<GroceryStore>> getAll() async =>
      _box.getAll().map((e) => e.toEntity()).toList();

  @override
  Future<GroceryStore?> getById(int id) async => _box.get(id)?.toEntity();

  @override
  Future<void> save(GroceryStore store) async {
    final model = GroceryStoreModel.fromEntity(store);
    _box.put(model);
  }

  @override
  Stream<List<GroceryStore>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) =>
        query.find().map((e) => e.toEntity()).toList());
  }
}
