import 'dart:async';

import 'package:smart_shopper/data/models/product_line_model.dart';
import 'package:smart_shopper/domain/entities/product_line.dart';
import 'package:smart_shopper/domain/repositories/product_line_repository.dart';
import 'package:smart_shopper/objectbox.g.dart';

/// Concrete implementation of [IProductLineRepository] using ObjectBox.
/// This class handles all the CRUD operations for the [ProductLine] entity.
//MARK: OBJECTBOX
class ProductLineBox implements ProductLineRepository {
  late final Box<ProductLineModel> _box;

  /// Constructor requires a [Store] to initialize the product line box.
  ProductLineBox(Store store) {
    _box = store.box<ProductLineModel>();
  }

  @override
  Stream<List<ProductLine>> getProductLinesStream() {
    final query = _box
        .query()
        .order(ProductLineModel_.name)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find().map((e) => e.toEntity()).toList());
  }

  @override
  Future<List<ProductLine>> getAllProductLines() async {
    final productLines = _box.getAll();
    productLines.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return productLines.map((e) => e.toEntity()).toList();
  }

  @override
  Future<ProductLine?> getProductLineById(int id) async {
    return _box.get(id)?.toEntity();
  }

  @override
  Future<int> addProductLine(ProductLine productLine) async {
    return _box.put(ProductLineModel.fromEntity(productLine));
  }

  @override
  Future<void> updateProductLine(ProductLine productLine) async {
    _box.put(ProductLineModel.fromEntity(productLine));
  }

  @override
  Future<bool> deleteProductLine(int id) async {
    return _box.remove(id);
  }

  @override
  Future<List<ProductLine>> getProductLinesForBrand(int brandId) async {
    final query =
        _box.query(ProductLineModel_.brand.equals(brandId)).build();
    final productLines = query.find();
    productLines.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    query.close();
    return productLines.map((e) => e.toEntity()).toList();
  }
}
