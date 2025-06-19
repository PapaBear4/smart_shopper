import 'dart:async';
import '../models/brand.dart';
import '../objectbox_helper.dart';
import '../objectbox.g.dart';

abstract class IProductLineRepository {
  Stream<List<ProductLine>> getProductLinesStream();
  Future<List<ProductLine>> getAllProductLines();
  Future<ProductLine?> getProductLineById(int id);
  Future<int> addProductLine(ProductLine productLine);
  Future<void> updateProductLine(ProductLine productLine);
  Future<bool> deleteProductLine(int id);
  Future<List<ProductLine>> getProductLinesForBrand(int brandId);
}

class ProductLineRepository implements IProductLineRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<ProductLine> _productLineBox;

  ProductLineRepository(this._objectBoxHelper) {
    _productLineBox = _objectBoxHelper.productLineBox;
  }

  @override
  Stream<List<ProductLine>> getProductLinesStream() {
    final query = _productLineBox.query().order(ProductLine_.name).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<ProductLine>> getAllProductLines() async {
    final productLines = _productLineBox.getAll();
    productLines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return productLines;
  }

  @override
  Future<ProductLine?> getProductLineById(int id) async {
    return _productLineBox.get(id);
  }

  @override
  Future<int> addProductLine(ProductLine productLine) async {
    return _productLineBox.put(productLine);
  }

  @override
  Future<void> updateProductLine(ProductLine productLine) async {
    _productLineBox.put(productLine);
  }

  @override
  Future<bool> deleteProductLine(int id) async {
    return _productLineBox.remove(id);
  }

  @override
  Future<List<ProductLine>> getProductLinesForBrand(int brandId) async {
    final query = _productLineBox.query(ProductLine_.brand.equals(brandId)).build();
    return query.find();
  }
}
