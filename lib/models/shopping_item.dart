import 'package:objectbox/objectbox.dart';
import 'shopping_list.dart'; // Import needed for relationships
import 'grocery_store.dart';       // Import needed for relationships

@Entity()
class ShoppingItem {
  @Id()
  int id = 0;

  String name;
  String category; // We'll use String for simplicity now
  double quantity; // Use double for quantities like 1.5
  String unit;
  bool isCompleted = false; // Default value

  // Establishes a many-to-one relationship to ShoppingList
  final shoppingList = ToOne<ShoppingList>();

  // Establishes a many-to-many relationship with Store
  final groceryStores = ToMany<GroceryStore>();

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