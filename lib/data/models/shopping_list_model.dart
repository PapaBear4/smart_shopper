import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/product_variant_model.dart';
import 'package:smart_shopper/data/models/shopping_item_model.dart';
import 'package:smart_shopper/domain/entities/shopping_list.dart';

@Entity()
class ShoppingListModel {
  @Id()
  int id = 0;
  String name;

  @Backlink('shoppingList')
  final items = ToMany<ShoppingItemModel>();

  final productVariants = ToMany<ProductVariantModel>();

  ShoppingListModel({
    this.id = 0,
    required this.name,
  });

  factory ShoppingListModel.fromEntity(ShoppingList entity) {
    return ShoppingListModel(
      id: entity.id,
      name: entity.name,
    );
  }

  ShoppingList toEntity() {
    return ShoppingList(
      id: id,
      name: name,
      items: items.map((item) => item.toEntity()).toList(),
      productVariants: productVariants.map((pv) => pv.toEntity()).toList(),
    );
  }
}
