import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart';
import 'brand.dart';

@Entity()
class PriceEntry {
  @Id()
  int id = 0;

  double price;
  @Property(type: PropertyType.date) // Store as int in DB, access as DateTime
  DateTime date;
  String canonicalItemName;

  final groceryStore = ToOne<GroceryStore>();
  final brand = ToOne<Brand>();

  PriceEntry({
    this.id = 0,
    required this.price,
    required this.date,
    required this.canonicalItemName,
  });
}
