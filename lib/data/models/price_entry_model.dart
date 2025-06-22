import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/grocery_store_model.dart';
import 'package:smart_shopper/data/models/product_variant_model.dart';
import 'package:smart_shopper/domain/entities/price_entry.dart';

@Entity()
class PriceEntryModel {
  @Id()
  int id = 0;

  double unitPrice;
  String unit;
  DateTime date;
  bool isPurchase;
  double? quantityPurchased;
  double? totalPricePaid;

  final productVariant = ToOne<ProductVariantModel>();
  final groceryStore = ToOne<GroceryStoreModel>();

  PriceEntryModel({
    this.id = 0,
    required this.unitPrice,
    required this.unit,
    required this.date,
    this.isPurchase = false,
    this.quantityPurchased,
    this.totalPricePaid,
  });

  factory PriceEntryModel.fromEntity(PriceEntry entity) {
    final model = PriceEntryModel(
      id: entity.id,
      unitPrice: entity.unitPrice,
      unit: entity.unit,
      date: entity.date,
      isPurchase: entity.isPurchase,
      quantityPurchased: entity.quantityPurchased,
      totalPricePaid: entity.totalPricePaid,
    );

    // Relationships must be set separately by the repository
    model.productVariant.target = ProductVariantModel.fromEntity(entity.productVariant);
    model.groceryStore.target = GroceryStoreModel.fromEntity(entity.groceryStore);

    return model;
  }

  PriceEntry toEntity() {
    // The entity requires non-nullable relations. If the target is null,
    // it indicates a data integrity issue, as a price entry should always
    // be linked to a product and a store.
    final productVariantEntity = productVariant.target?.toEntity();
    final groceryStoreEntity = groceryStore.target?.toEntity();

    if (productVariantEntity == null) {
      throw StateError('ProductVariant relation is not set for PriceEntryModel id: $id');
    }
    if (groceryStoreEntity == null) {
      throw StateError('GroceryStore relation is not set for PriceEntryModel id: $id');
    }

    return PriceEntry(
      id: id,
      unitPrice: unitPrice,
      unit: unit,
      date: date,
      isPurchase: isPurchase,
      quantityPurchased: quantityPurchased,
      totalPricePaid: totalPricePaid,
      productVariant: productVariantEntity,
      groceryStore: groceryStoreEntity,
    );
  }
}
