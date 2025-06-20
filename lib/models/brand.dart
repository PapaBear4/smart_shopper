import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart'; // Import for ToMany<GroceryStore>

/// Represents a brand of a product.
///
/// This class is used to store information about different brands
/// and their relationships with [GroceryStore]s and [ShoppingItem]s.
@Entity()
class Brand {
  /// The unique identifier for the brand.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The name of the brand (e.g., "Heinz", "Kraft").
  String name;

  /// A list of grocery stores that carry this brand.
  /// This establishes a many-to-many relationship with [GroceryStore].
  /// The `Backlink` annotation indicates that the `brands` field in the
  /// [GroceryStore] entity links back to this relationship.
  @Backlink('brands') // Assuming 'brands' will be the ToMany<Brand> field in GroceryStore
  final groceryStores = ToMany<GroceryStore>();

  /// A list of sub-brands associated with this brand.
  /// This establishes a one-to-many relationship, where one brand can
  /// have multiple sub-brands.
  /// The `Backlink` annotation indicates that the `brand` field in the
  /// [SubBrand] entity links back to this relationship.
  @Backlink('brand')
  final subBrands = ToMany<SubBrand>();

  /// A list of product lines associated with this brand.
  /// This establishes a one-to-many relationship, where one brand can
  /// have multiple product lines.
  /// The `Backlink` annotation indicates that the `brand` field in the
  /// [ProductLine] entity links back to this relationship.
  @Backlink('brand')
  final productLines = ToMany<ProductLine>();

  /// Creates a new [Brand] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [name] of the brand is required.
  Brand({
    this.id = 0,
    required this.name,
  });
}

/// Represents a sub-brand under a main brand.
@Entity()
class SubBrand {
  /// The unique identifier for the sub-brand.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The name of the sub-brand.
  String name;

  /// The parent brand for this sub-brand.
  /// This establishes a many-to-one relationship, where multiple sub-brands
  /// can belong to a single brand.
  final brand = ToOne<Brand>();

  /// Creates a new [SubBrand] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [name] of the sub-brand is required.
  SubBrand({
    this.id = 0,
    required this.name,
  });
}

/// Represents a product line under a main brand.
@Entity()
class ProductLine {
  /// The unique identifier for the product line.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The name of the product line.
  String name;

  /// The parent brand for this product line.
  /// This establishes a many-to-one relationship, where multiple product lines
  /// can belong to a single brand.
  final brand = ToOne<Brand>();

  /// Creates a new [ProductLine] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [name] of the product line is required.
  ProductLine({
    this.id = 0,
    required this.name,
  });
}
