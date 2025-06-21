import 'dart:async';
import '../entities/product_line.dart';

/// Defines the interface for product line data operations.
abstract class ProductLineRepository {
  /// Returns a stream of all product lines.
  Stream<List<ProductLine>> getProductLinesStream();

  /// Gets all product lines.
  Future<List<ProductLine>> getAllProductLines();

  /// Gets a single product line by its ID.
  Future<ProductLine?> getProductLineById(int id);

  /// Adds a new product line.
  Future<int> addProductLine(ProductLine productLine);

  /// Updates an existing product line.
  Future<void> updateProductLine(ProductLine productLine);

  /// Deletes a product line by its ID.
  Future<bool> deleteProductLine(int id);

  /// Gets all product lines for a given brand ID.
  Future<List<ProductLine>> getProductLinesForBrand(int brandId);
}
