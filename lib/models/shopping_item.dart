import 'package:objectbox/objectbox.dart';
import 'shopping_list.dart'; // Import needed for relationships
import 'grocery_store.dart';       // Import needed for relationships
import 'displayable_item.dart'; // Added
import 'product_variant.dart'; // Added for preferredVariant

/// Represents an item on a [ShoppingList].
///
/// This class implements [DisplayableItem] to be easily used in UI lists.
/// It stores details about what the user wants to buy, including its name,
/// quantity, desired attributes, and relationships to [ShoppingList],
/// [GroceryStore], and a preferred [ProductVariant].
@Entity()
class ShoppingItem implements DisplayableItem { // Implemented DisplayableItem
  /// The unique identifier for the shopping item.
  /// This is automatically assigned by ObjectBox.
  @Id()
  @override // Added
  int id = 0;

  /// The general name of the item as entered by the user (e.g., "Jelly", "Milk").
  @override // Added
  String name;

  /// The category of the shopping item (e.g., "Dairy", "Produce"). This field is optional.
  String? category;

  /// The quantity of the item to be purchased. Defaults to 1.0.
  double quantity; // Kept as required for now, will default in constructor or UI

  /// The unit of measurement for the quantity (e.g., "kg", "lbs", "liters", "pcs"). This field is optional.
  String? unit; // Made nullable

  /// Indicates whether this shopping item has been purchased or completed. Defaults to `false`.
  @override // Added
  bool isCompleted = false; // Default value

  /// Any additional notes or raw input from the user regarding this item.
  String? notes; // For user's raw input or additional details

  /// A list of desired attributes for the item specified by the user
  /// (e.g., ["grape", "organic", "large"]). This helps in finding a suitable [ProductVariant].
  List<String> desiredAttributes = [];

  /// An optional link to a specific [ProductVariant] that the user prefers or has selected for this item.
  final preferredVariant = ToOne<ProductVariant>();

  /// A link to the [ShoppingList] this item belongs to.
  /// This establishes a many-to-one relationship.
  // TODO: Consider making this a many-to-many to support duplicate lists
  final shoppingList = ToOne<ShoppingList>();

  /// A list of [GroceryStore]s where this item might be available or is typically purchased from.
  /// This establishes a many-to-many relationship.
  final groceryStores = ToMany<GroceryStore>();

  /// Creates a new [ShoppingItem] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [name] of the item is required.
  /// [category], [unit], [notes] are optional.
  /// [quantity] defaults to 1.0 if not specified.
  /// [isCompleted] defaults to `false` if not specified.
  /// [desiredAttributes] defaults to an empty list if not provided.
  /// ToOne relations ([preferredVariant], [shoppingList]) are set separately after instantiation.
  ShoppingItem({
    this.id = 0,
    required this.name,
    this.category,
    this.quantity = 1.0,
    this.unit,
    this.isCompleted = false,
    this.notes,
    List<String>? desiredAttributes,
    // preferredVariant ToOne is not initialized in constructor directly
  }) : desiredAttributes = desiredAttributes ?? [];

  /// Converts this [ShoppingItem] instance to a JSON map.
  /// Useful for debugging and logging purposes.
  // For debugging and logging
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'isCompleted': isCompleted,
        'notes': notes,
        'desiredAttributes': desiredAttributes,
        'preferredVariant': preferredVariant.target?.id, // Log variant ID if exists
        'shoppingList': shoppingList.target?.id, // Log list ID if exists
        'groceryStores': groceryStores.map((s) => s.id).toList(), // Log store IDs
      };

  /// Returns a string representation of the [ShoppingItem].
  /// Useful for debugging and logging.
  @override
  String toString() {
    return 'ShoppingItem{id: $id, name: $name, quantity: $quantity, unit: $unit, isCompleted: $isCompleted, attributes: ${desiredAttributes.join(", ")}}';
  }
}