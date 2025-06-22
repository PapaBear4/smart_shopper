import 'package:equatable/equatable.dart';
import 'package:smart_shopper/domain/entities/product_variant.dart';
import 'package:smart_shopper/domain/entities/shopping_item.dart';

/// Represents a list of [ShoppingItem]s.
///
/// Users can create multiple shopping lists (e.g., "Weekly Groceries", "Party Supplies").
class ShoppingList extends Equatable {
  final int id;
  final String name;

  /// A list of [ShoppingItem]s included in this shopping list.
  final List<ShoppingItem> items;

  /// A list of specific [ProductVariant]s that are directly 
  /// associated with this shopping list.
  final List<ProductVariant> productVariants;

  /// Creates a new [ShoppingList] instance.
  const ShoppingList({
    required this.id,
    required this.name,
    this.items = const [],
    this.productVariants = const [],
  });

  @override
  List<Object?> get props => [id, name, items, productVariants];
}