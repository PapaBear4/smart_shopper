import 'package:smart_shopper/data/models/product_variant_model.dart';
import 'package:smart_shopper/domain/entities/product_variant.dart';
import 'package:smart_shopper/domain/repositories/product_variant_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

class ProductVariantBox implements ProductVariantRepository {
  final Box<ProductVariantModel> _box;

  ProductVariantBox(Store store) : _box = store.box<ProductVariantModel>();

  @override
  Future<void> delete(int id) async => _box.remove(id);

  @override
  Future<List<ProductVariant>> getAll() async =>
      _box.getAll().map((e) => e.toEntity()).toList();

  @override
  Future<ProductVariant?> getById(int id) async => _box.get(id)?.toEntity();

  @override
  Future<void> save(ProductVariant variant) async {
    final model = ProductVariantModel.fromEntity(variant);
    // TODO: Handle relationships
    _box.put(model);
  }

  @override
  Stream<List<ProductVariant>> watchAll() {
    return _box.query().watch(triggerImmediately: true).map((query) =>
        query.find().map((e) => e.toEntity()).toList());
  }
}
