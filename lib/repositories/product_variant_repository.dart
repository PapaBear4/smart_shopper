// Imports the necessary Dart async library for handling asynchronous operations.
import 'dart:async';

// Imports the data models used within the repository, such as ProductVariant.
import '../models/models.dart';

// Imports a helper class for ObjectBox, which simplifies database interactions.
import '../objectbox_helper.dart';

// Imports the generated ObjectBox file, which contains the database schema and query builders.
import '../objectbox.g.dart';

/// Abstract class defining the contract for a product variant repository.
/// This interface specifies the methods that any class implementing it must provide.
/// MARK: ABSTRACT
abstract class IProductVariantRepository {
  /// Returns a stream of all product variants.
  /// The stream will emit a new list of variants whenever the data changes.
  Stream<List<ProductVariant>> getProductVariantsStream();

  /// Retrieves a list of all product variants from the database.
  /// This is a one-time fetch and does not update automatically.
  Future<List<ProductVariant>> getAllProductVariants();

  /// Retrieves a single product variant by its unique ID.
  /// Returns null if no variant is found with the given ID.
  Future<ProductVariant?> getProductVariantById(int id);

  /// Adds a new product variant to the database.
  /// Returns the ID of the newly added variant.
  Future<int> addProductVariant(ProductVariant variant);

  /// Updates an existing product variant in the database.
  Future<void> updateProductVariant(ProductVariant variant);

  /// Deletes a product variant from the database by its unique ID.
  /// Returns true if the deletion was successful, false otherwise.
  Future<bool> deleteProductVariant(int id);

  /// Finds all product variants that share a common base product name.
  Future<List<ProductVariant>> findVariantsByBaseName(String baseProductName);

  /// Finds all product variants associated with a specific brand ID.
  Future<List<ProductVariant>> findVariantsByBrand(int brandId);

  /// Searches for product variants based on a search term and optional brand ID.
  /// The search is case-insensitive and checks the variant's name and base product name.
  Future<List<ProductVariant>> searchVariants(
    String searchTerm, {
    int? brandId,
  });
}

/// Concrete implementation of the IProductVariantRepository interface.
/// This class handles the actual database operations for product variants using ObjectBox.
/// MARK: OBJECTBOX
class ProductVariantRepository implements IProductVariantRepository {
  /// Instance of the ObjectBox helper class to interact with the database.
  final ObjectBoxHelper _objectBoxHelper;

  /// The ObjectBox "box" for storing and retrieving ProductVariant objects.
  late final Box<ProductVariant> _variantBox;

  /// Constructor for the ProductVariantRepository.
  /// It initializes the ObjectBox helper and the product variant box.
  ProductVariantRepository(this._objectBoxHelper) {
    _variantBox = _objectBoxHelper.productVariantBox;
  }

  /// Returns a stream of all product variants, ordered by their base product name.
  /// The stream is configured to trigger immediately with the current data.
  @override
  Stream<List<ProductVariant>> getProductVariantsStream() {
    final query = _variantBox
        .query()
        .order(ProductVariant_.baseProductName)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  /// Retrieves a list of all product variants from the database.
  /// The variants are sorted alphabetically by their base product name.
  @override
  Future<List<ProductVariant>> getAllProductVariants() async {
    final variants = _variantBox.getAll();
    variants.sort((a, b) {
      final baseNameComparison = a.baseProductName.toLowerCase().compareTo(
        b.baseProductName.toLowerCase(),
      );
      if (baseNameComparison != 0) {
        return baseNameComparison;
      }
      // If base names are the same, sort by variant name
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return variants;
  }

  /// Retrieves a single product variant by its unique ID from the ObjectBox store.
  @override
  Future<ProductVariant?> getProductVariantById(int id) async {
    return _variantBox.get(id);
  }

  /// Adds or updates a product variant in the ObjectBox store.
  /// ObjectBox's `put` method handles both creation and updates.
  /// Returns the ID of the inserted or updated variant.
  @override
  Future<int> addProductVariant(ProductVariant variant) async {
    return _variantBox.put(variant);
  }

  /// Updates an existing product variant in the ObjectBox store.
  /// This method also uses the `put` method, as it will overwrite the existing entry.
  @override
  Future<void> updateProductVariant(ProductVariant variant) async {
    _variantBox.put(variant);
  }

  /// Deletes a product variant from the ObjectBox store by its ID.
  /// Returns true if the item was successfully removed, false otherwise.
  @override
  Future<bool> deleteProductVariant(int id) async {
    return _variantBox.remove(id);
  }

  /// Finds all product variants that have a specific base product name.
  /// This is useful for grouping different variations of the same product.
  @override
  Future<List<ProductVariant>> findVariantsByBaseName(
    String baseProductName,
  ) async {
    final query =
        _variantBox
            .query(ProductVariant_.baseProductName.equals(baseProductName))
            .build();
    return query.find();
  }

  /// Finds all product variants belonging to a specific brand.
  /// The brand is identified by its ID.
  @override
  Future<List<ProductVariant>> findVariantsByBrand(int brandId) async {
    final query =
        _variantBox.query(ProductVariant_.brand.equals(brandId)).build();
    return query.find();
  }

  /// Searches for product variants using a search term and an optional brand ID.
  /// This allows for flexible filtering of the product variants.
  @override
  Future<List<ProductVariant>> searchVariants(
    String searchTerm, {
    int? brandId,
  }) async {
    final lowerSearchTerm = searchTerm.toLowerCase();

    // Start building a query for ProductVariant objects.
    QueryBuilder<ProductVariant> queryBuilder = _variantBox.query();
    Condition<ProductVariant>? searchCondition;
    Condition<ProductVariant>? brandCondition;

    // If a search term is provided, create a condition to search by name and base product name.
    if (lowerSearchTerm.isNotEmpty) {
      searchCondition = ProductVariant_.name
          .contains(lowerSearchTerm, caseSensitive: false)
          .or(
            ProductVariant_.baseProductName.contains(
              lowerSearchTerm,
              caseSensitive: false,
            ),
          );
      // Additional fields can be added to the search condition if needed.
      // e.g., .or(ProductVariant_.flavor.contains(lowerSearchTerm, caseSensitive: false))
    }

    // If a brand ID is provided, create a condition to filter by that brand.
    if (brandId != null) {
      brandCondition = ProductVariant_.brand.equals(brandId);
    }

    // Combine the search and brand conditions if both are present.
    if (searchCondition != null && brandCondition != null) {
      queryBuilder = _variantBox.query(searchCondition.and(brandCondition));
    } else if (searchCondition != null) {
      queryBuilder = _variantBox.query(searchCondition);
    } else if (brandCondition != null) {
      queryBuilder = _variantBox.query(brandCondition);
    }
    // If no conditions are provided, the query will return all variants.

    // Build the final query, ordering the results by the variant name.
    final query = queryBuilder.order(ProductVariant_.name).build();
    final variants = query.find();
    // The query now handles sorting, but manual sorting can be re-enabled if needed.
    // variants.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return variants;
  }
}
