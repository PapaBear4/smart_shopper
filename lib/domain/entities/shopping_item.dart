import 'package:equatable/equatable.dart';
import 'package:smart_shopper/domain/entities/grocery_store.dart';
import 'package:smart_shopper/domain/entities/product_variant.dart';

/// Represents an item on a shopping list.
class ShoppingItem extends Equatable {
  final int id;
  final String name;
  final String? category;
  final double quantity;
  final String? unit;
  final bool isCompleted;
  final String? notes;
  final List<String> desiredAttributes;
  final ProductVariant? preferredVariant;
  final List<GroceryStore> groceryStores;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.category,
    this.quantity = 1.0,
    this.unit,
    this.isCompleted = false,
    this.notes,
    this.desiredAttributes = const [],
    this.preferredVariant,
    this.groceryStores = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        quantity,
        unit,
        isCompleted,
        notes,
        desiredAttributes,
        preferredVariant,
        groceryStores,
      ];
}
