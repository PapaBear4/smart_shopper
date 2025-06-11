import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart';
// import 'brand.dart'; // Brand will now be on ProductVariant
import 'product_variant.dart'; // Added

@Entity()
class PriceEntry {
  @Id()
  int id = 0;

  double price;
  @Property(type: PropertyType.date) // Store as int in DB, access as DateTime
  DateTime date;
  // String canonicalItemName; // Replaced by link to ProductVariant

  final groceryStore = ToOne<GroceryStore>();
  // final brand = ToOne<Brand>(); // Replaced by ProductVariant's brand
  final productVariant = ToOne<ProductVariant>(); // Link to the specific product

  PriceEntry({
    this.id = 0,
    required this.price,
    required this.date,
    // required this.canonicalItemName, // Removed
  });
}
