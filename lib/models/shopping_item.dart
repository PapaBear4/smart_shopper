import 'package:objectbox/objectbox.dart';
import 'shopping_list.dart'; // Import needed for relationships
import 'grocery_store.dart';       // Import needed for relationships
import 'brand.dart'; // Import for ToOne<Brand>
import 'price_entry.dart'; // Import for PriceEntry
import 'displayable_item.dart'; // Added
import 'product_variant.dart'; // Added for preferredVariant

@Entity()
class ShoppingItem implements DisplayableItem { // Implemented DisplayableItem
  @Id()
  @override // Added
  int id = 0;

  @override // Added
  String name; // General name like "Jelly", "Milk"
  String? category; // Made nullable
  double quantity; // Kept as required for now, will default in constructor or UI
  String? unit; // Made nullable
  @override // Added
  bool isCompleted = false; // Default value
  String? notes; // For user's raw input or additional details

  List<String> desiredAttributes = []; // e.g., ["grape", "organic", "large"]

  // Optional: Link to a specific product variant if known/selected by the user
  final preferredVariant = ToOne<ProductVariant>();

  // Establishes a many-to-one relationship to ShoppingList
  final shoppingList = ToOne<ShoppingList>();

  // Establishes a many-to-many relationship with Store
  final groceryStores = ToMany<GroceryStore>();

  // Reference to a brand - this might become less used if brand is primarily on ProductVariant
  final brand = ToOne<Brand>();

  @Transient() // This field is not stored in the database
  List<PriceEntry> priceEntries = [];

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
    // brand ToOne is not initialized in constructor directly
  }) : this.desiredAttributes = desiredAttributes ?? [];
}