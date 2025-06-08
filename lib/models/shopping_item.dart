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
  String category; // We'll use String for simplicity now
  double quantity; // Use double for quantities like 1.5
  String unit;
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
    required this.category,
    required this.quantity,
    required this.unit,
    this.isCompleted = false,
    // Note: We don't initialize ToOne/ToMany fields in the constructor
  });
}