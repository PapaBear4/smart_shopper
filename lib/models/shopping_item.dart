import 'package:objectbox/objectbox.dart';
import 'shopping_list.dart'; // Import needed for relationships
import 'grocery_store.dart';       // Import needed for relationships
import 'brand.dart'; // Import for ToOne<Brand>
import 'price_entry.dart'; // Import for PriceEntry
import 'displayable_item.dart'; // Added

@Entity()
class ShoppingItem implements DisplayableItem { // Implemented DisplayableItem
  @Id()
  @override // Added
  int id = 0;

  @override // Added
  String name;
  String? category; // Made nullable
  double quantity; // Kept as required for now, will default in constructor or UI
  String? unit; // Made nullable
  @override // Added
  bool isCompleted = false; // Default value

  // Establishes a many-to-one relationship to ShoppingList
  final shoppingList = ToOne<ShoppingList>();

  // Establishes a many-to-many relationship with Store
  final groceryStores = ToMany<GroceryStore>();

  // Reference to a brand
  final brand = ToOne<Brand>();

  @Transient() // This field is not stored in the database
  List<PriceEntry> priceEntries = [];

  ShoppingItem({
    this.id = 0,
    required this.name,
    this.category, // No longer required
    this.quantity = 1.0, // Default quantity to 1
    this.unit, // No longer required
    this.isCompleted = false,
    // Note: We don't initialize ToOne/ToMany fields in the constructor
  });
}