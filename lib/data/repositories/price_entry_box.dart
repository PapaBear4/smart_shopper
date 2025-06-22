import 'package:smart_shopper/data/models/price_entry_model.dart';
import 'package:smart_shopper/domain/entities/price_entry.dart';
import 'package:smart_shopper/domain/repositories/price_entry_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

class PriceEntryBox implements PriceEntryRepository {
  final Box<PriceEntryModel> _box;

  PriceEntryBox(Store store) : _box = store.box<PriceEntryModel>();

  @override
  Future<void> delete(int id) async => _box.remove(id);

  @override
  Future<List<PriceEntry>> getAll() async =>
      _box.getAll().map((e) => e.toEntity()).toList();

  @override
  Future<PriceEntry?> getById(int id) async => _box.get(id)?.toEntity();

  @override
  Future<void> save(PriceEntry entry) async {
    final model = PriceEntryModel.fromEntity(entry);
    // TODO: Handle relationships
    _box.put(model);
  }

  @override
  Stream<List<PriceEntry>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) =>
        query.find().map((e) => e.toEntity()).toList());
  }
}
