import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart';
import '../objectbox.g.dart';

/// Defines the interface for product line data operations.
/// This abstraction is crucial for decoupling the application logic
/// from the database implementation, allowing for easier testing and maintenance.
//MARK: ABSTRACT
abstract class IProductLineRepository {
  /// Returns a stream of all product lines, sorted by name.
  /// The stream updates automatically when the data changes.
  Stream<List<ProductLine>> getProductLinesStream();

  /// Fetches all product lines from the database once.
  Future<List<ProductLine>> getAllProductLines();

  /// Fetches a single product line by its unique ID.
  Future<ProductLine?> getProductLineById(int id);

  /// Adds a new product line to the database.
  /// Returns the ID of the newly created product line.
  Future<int> addProductLine(ProductLine productLine);

  /// Updates an existing product line in the database.
  Future<void> updateProductLine(ProductLine productLine);

  /// Deletes a product line from the database by its ID.
  /// Returns true if the deletion was successful.
  Future<bool> deleteProductLine(int id);

  /// Fetches all product lines associated with a specific brand ID.
  Future<List<ProductLine>> getProductLinesForBrand(int brandId);
}

/// Concrete implementation of [IProductLineRepository] using ObjectBox.
/// This class handles all the CRUD operations for the [ProductLine] entity.
//MARK: OBJECTBOX
class ProductLineRepository implements IProductLineRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<ProductLine> _productLineBox;

  /// Constructor requires an [ObjectBoxHelper] to initialize the product line box.
  ProductLineRepository(this._objectBoxHelper) {
    _productLineBox = _objectBoxHelper.productLineBox;
  }

  @override
  Stream<List<ProductLine>> getProductLinesStream() {
    // Create a query for all ProductLine objects, ordered by name.
    // .watch() creates a reactive stream.
    final query = _productLineBox.query().order(ProductLine_.name).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<ProductLine>> getAllProductLines() async {
    // .getAll() retrieves all objects from the box.
    final productLines = _productLineBox.getAll();
    // Sort the list alphabetically by name.
    productLines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return productLines;
  }

  @override
  Future<ProductLine?> getProductLineById(int id) async {
    // .get() retrieves a single object by its ID.
    return _productLineBox.get(id);
  }

  @override
  Future<int> addProductLine(ProductLine productLine) async {
    // .put() inserts or updates an object and returns its ID.
    return _productLineBox.put(productLine);
  }

  @override
  Future<void> updateProductLine(ProductLine productLine) async {
    // .put() is also used for updates.
    _productLineBox.put(productLine);
  }

  @override
  Future<bool> deleteProductLine(int id) async {
    // .remove() deletes an object by its ID.
    return _productLineBox.remove(id);
  }

  @override
  Future<List<ProductLine>> getProductLinesForBrand(int brandId) async {
    // This method demonstrates a query based on a ToOne relationship.
    // It finds all ProductLine entities where the `brand` relation
    // points to the given `brandId`.
    final query = _productLineBox.query(ProductLine_.brand.equals(brandId)).build();
    final productLines = query.find();
    // It's good practice to sort the results for consistent UI.
    productLines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    query.close(); // Always close queries when you're done with them.
    return productLines;
  }
}
