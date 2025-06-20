import 'package:objectbox/objectbox.dart';
import 'shopping_item.dart'; // Import needed for the relationship
import 'product_variant.dart'; // Import for ToMany<ProductVariant>

/// Represents a list of [ShoppingItem]s.
///
/// Users can create multiple shopping lists (e.g., "Weekly Groceries", "Party Supplies").
@Entity()
class ShoppingList {
  /// The unique identifier for the shopping list.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The name of the shopping list (e.g., "Weekly Groceries").
  String name;

  /// A list of [ShoppingItem]s included in this shopping list.
  /// This establishes a one-to-many relationship, where one shopping list
  /// can contain multiple shopping items.
  /// The `@Backlink('shoppingList')` annotation indicates that the `shoppingList`
  /// field in the [ShoppingItem] entity links back to this [ShoppingList].
  @Backlink('shoppingList')
  final items = ToMany<ShoppingItem>();

  /// A list of specific [ProductVariant]s that are directly associated with this shopping list.
  /// This establishes the owning side of a many-to-many relationship with [ProductVariant].
  /// This can be used for items the user frequently buys or wants to track on this list
  /// independent of the regular shopping items flow.
  final productVariants = ToMany<ProductVariant>();

  /// Creates a new [ShoppingList] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [name] of the shopping list is required.
  ShoppingList({
    this.id = 0,
    required this.name,
  });
}