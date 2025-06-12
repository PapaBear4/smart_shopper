import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart';
// import 'brand.dart'; // Removed, brand is on ProductVariant
import 'product_variant.dart'; // Added

@Entity()
class PriceEntry {
  @Id()
  int id = 0;

  double price;
  @Property(type: PropertyType.date) // Store as int in DB, access as DateTime
  DateTime date;
  // String canonicalItemName; // Removed

  final groceryStore = ToOne<GroceryStore>();
  // final brand = ToOne<Brand>(); // Removed
  final productVariant = ToOne<ProductVariant>(); // Added

  PriceEntry({
    this.id = 0,
    required this.price,
    required this.date,
    // required this.canonicalItemName, // Removed
    // productVariant ToOne is not initialized directly in constructor
  });
}
