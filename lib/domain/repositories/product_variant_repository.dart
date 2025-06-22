import 'package:smart_shopper/domain/entities/product_variant.dart';

/// Repository for managing product variants.
abstract class ProductVariantRepository {
  /// Retrieves all product variants.
  Future<List<ProductVariant>> getAll();

  /// Retrieves a single product variant by its ID.
  Future<ProductVariant?> getById(int id);

  /// Saves a product variant (creates if new, updates if exists).
  Future<void> save(ProductVariant variant);

  /// Deletes a product variant by its ID.
  Future<void> delete(int id);

  /// Watches for changes to all product variants.
  Stream<List<ProductVariant>> watchAll();
}
