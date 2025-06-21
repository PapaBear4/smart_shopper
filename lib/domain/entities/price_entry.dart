import 'package:equatable/equatable.dart';
import 'package:smart_shopper/domain/entities/grocery_store.dart';
import 'package:smart_shopper/domain/entities/product_variant.dart';

/// Represents a price record for a specific [ProductVariant] at a [GroceryStore] on a given date.
class PriceEntry extends Equatable {
  final int id;
  final double unitPrice;
  final String unit;
  final DateTime date;
  final bool isPurchase;
  final double? quantityPurchased;
  final double? totalPricePaid;
  final GroceryStore groceryStore;
  final ProductVariant productVariant;

  const PriceEntry({
    required this.id,
    required this.unitPrice,
    required this.unit,
    required this.date,
    this.isPurchase = false,
    this.quantityPurchased,
    this.totalPricePaid,
    required this.groceryStore,
    required this.productVariant,
  });

  @override
  List<Object?> get props => [
        id,
        unitPrice,
        unit,
        date,
        isPurchase,
        quantityPurchased,
        totalPricePaid,
        groceryStore,
        productVariant,
      ];
}
