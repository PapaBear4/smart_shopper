//lib/models/grocery_store.dart
import 'package:objectbox/objectbox.dart';
import 'brand.dart'; // Import for ToMany<Brand>
import 'product_variant.dart'; // Import for ToMany<ProductVariant>

/// Represents a grocery store where items can be purchased.
///
/// This class stores details about a grocery store, including its name,
/// contact information, store number, and the [Brand]s it carries.
@Entity()
class GroceryStore {
  /// The unique identifier for the grocery store.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The name of the grocery store (e.g., "Walmart", "Kroger"). This field is non-nullable.
  String name; // Non-nullable, must be initialized

  /// The website URL of the grocery store. This field is optional.
  String? website;

  /// The physical address of the grocery store. This field is optional.
  String? address;

  /// The phone number of the grocery store. This field is optional.
  String? phoneNumber;

  /// The store number (e.g., for chain stores, "Store #123"). This field is optional.
  String? storeNumber;

  /// A list of brands available at this grocery store.
  /// This establishes a many-to-many relationship with the [Brand] entity.
  final brands = ToMany<Brand>();

  /// A list of specific [ProductVariant]s that this grocery store carries.
  /// This establishes the owning side of a many-to-many relationship with [ProductVariant].
  final carriedProductVariants = ToMany<ProductVariant>();

  /// Creates a new [GroceryStore] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [name] of the grocery store is required.
  /// [website], [address], [phoneNumber], and [storeNumber] are optional.
  GroceryStore({
    this.id = 0,
    required this.name, // 'required' ensures 'name' is provided and initialized
    this.website,
    this.address,
    this.phoneNumber,
    this.storeNumber,
  });
}