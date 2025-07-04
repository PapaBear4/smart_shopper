import 'package:objectbox/objectbox.dart';
import 'grocery_store.dart';
import 'product_variant.dart'; // Added

/// Represents a price record for a specific [ProductVariant] at a [GroceryStore] on a given date.
///
/// This entity is used to track price history and compare prices across different
/// stores and times. Supports both fixed-size and variable-weight products.
@Entity()
class PriceEntry {
  /// The unique identifier for the price entry.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The unit price of the product (e.g., 3.99 for $3.99 per lb).
  double unitPrice;

  /// The unit for the unit price (e.g., "lb", "kg", "g", "oz", "count").
  String unit;

  /// The date when this price was recorded.
  /// Stored as an integer (timestamp) in the database but accessed as [DateTime].
  @Property(type: PropertyType.date) // Store as int in DB, access as DateTime
  DateTime date;

  /// The quantity purchased (optional, for actual purchase records; e.g., 1.25 for 1.25 lb).
  double? quantityPurchased;

  /// The total price paid (optional, for actual purchase records; e.g., 4.99 for $4.99 total).
  double? totalPricePaid;

  /// A link to the [GroceryStore] where this price was observed.
  final groceryStore = ToOne<GroceryStore>();

  /// A link to the specific [ProductVariant] this price entry pertains to.
  final productVariant = ToOne<ProductVariant>(); // Added

  /// Creates a new [PriceEntry] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// The [unitPrice], [unit], and [date] are required.
  /// The [groceryStore] and [productVariant] relations are set separately after instantiation.
  /// [quantityPurchased] and [totalPricePaid] are optional and used for actual purchase records.
  PriceEntry({
    this.id = 0,
    required this.unitPrice,
    required this.unit,
    required this.date,
    this.quantityPurchased,
    this.totalPricePaid,
  });

  /// Converts this [PriceEntry] instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'unitPrice': unitPrice,
        'unit': unit,
        'date': date.toIso8601String(),
        'quantityPurchased': quantityPurchased,
        'totalPricePaid': totalPricePaid,
        'groceryStore': groceryStore.target?.id,
        'productVariant': productVariant.target?.id,
      };

  @override
  String toString() {
    return 'PriceEntry{id: $id, unitPrice: $unitPrice, unit: $unit, date: $date, quantityPurchased: $quantityPurchased, totalPricePaid: $totalPricePaid, groceryStore:  27${groceryStore.target?.name} 27, productVariant: ${productVariant.target?.name}}';
  }
}
