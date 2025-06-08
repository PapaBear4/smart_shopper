import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart'; // Import for ToMany<GroceryStore>

@Entity()
class Brand {
  @Id()
  int id = 0;

  String name;

  // Establishes a many-to-many relationship with GroceryStore
  @Backlink('brands') // Assuming 'brands' will be the ToMany<Brand> field in GroceryStore
  final groceryStores = ToMany<GroceryStore>();

  Brand({
    this.id = 0,
    required this.name,
  });
}
