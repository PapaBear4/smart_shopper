import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart'; // Import for ToMany<GroceryStore>
import 'shopping_item.dart'; // Import for ToMany<ShoppingItem>

@Entity()
class Brand {
  @Id()
  int id = 0;

  String name;

  // Establishes a many-to-many relationship with GroceryStore
  @Backlink('brands') // Assuming 'brands' will be the ToMany<Brand> field in GroceryStore
  final groceryStores = ToMany<GroceryStore>();

  // Establishes a one-to-many relationship with ShoppingItem
  // This is the backlink to the 'brand' field in ShoppingItem
  @Backlink('brand')
  final shoppingItems = ToMany<ShoppingItem>();

  Brand({
    this.id = 0,
    required this.name,
  });
}
