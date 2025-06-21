import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/grocery_store_model.dart';
import 'package:smart_shopper/domain/entities/price_entry.dart';
import 'package:smart_shopper/domain/entities/product_variant.dart';

@Entity()
class PriceEntryModel {
  @Id()
  int id = 0;

  double unitPrice;
  String unit;
  @Property(type: PropertyType.date)
  DateTime date;
  bool isPurchase;
  double? quantityPurchased;
  double? totalPricePaid;

  final groceryStore = ToOne<GroceryStoreModel>();
  final productVariant = ToOne<ProductVariant>();

  PriceEntryModel({
    this.id = 0,
    required this.unitPrice,
    required this.unit,
    required this.date,
    this.isPurchase = false,
    this.quantityPurchased,
    this.totalPricePaid,
  });

  PriceEntry toEntity() {
    // First, ensure that the relations are set.
    if (groceryStore.target == null) {
      throw StateError('GroceryStore relation is not set for PriceEntryModel id: $id');
    }
    if (productVariant.target == null) {
      throw StateError('ProductVariant relation is not set for PriceEntryModel id: $id');
    }

    return PriceEntry(
      id: id,
      unitPrice: unitPrice,
      unit: unit,
      date: date,
      isPurchase: isPurchase,
      quantityPurchased: quantityPurchased,
      totalPricePaid: totalPricePaid,
      groceryStore: groceryStore.target!.toEntity(),
      // Note: ProductVariant is not yet refactored, so we pass it directly.
      productVariant: productVariant.target!,
    );
  }

  static PriceEntryModel fromEntity(PriceEntry entity) {
    final model = PriceEntryModel(
      id: entity.id,
      unitPrice: entity.unitPrice,
      unit: entity.unit,
      date: entity.date,
      isPurchase: entity.isPurchase,
      quantityPurchased: entity.quantityPurchased,
      totalPricePaid: entity.totalPricePaid,
    );

    model.groceryStore.target = GroceryStoreModel.fromEntity(entity.groceryStore);

    // Note: ProductVariant is not yet refactored, so we assign it directly.
    model.productVariant.target = entity.productVariant;

    return model;
  }
}
