import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/grocery_store_model.dart';
import 'package:smart_shopper/data/models/product_variant_model.dart';
import 'package:smart_shopper/data/models/shopping_list_model.dart';
import 'package:smart_shopper/domain/entities/shopping_item.dart';

@Entity()
class ShoppingItemModel {
  @Id()
  int id = 0;

  String name;
  String? category;
  double quantity;
  String? unit;
  bool isCompleted;
  String? notes;
  List<String> desiredAttributes;

  final preferredVariant = ToOne<ProductVariantModel>();
  final shoppingList = ToOne<ShoppingListModel>();
  final groceryStores = ToMany<GroceryStoreModel>();

  ShoppingItemModel({
    this.id = 0,
    required this.name,
    this.category,
    this.quantity = 1.0,
    this.unit,
    this.isCompleted = false,
    this.notes,
    this.desiredAttributes = const [],
  });

  factory ShoppingItemModel.fromEntity(ShoppingItem entity) {
    final model = ShoppingItemModel(
      id: entity.id,
      name: entity.name,
      category: entity.category,
      quantity: entity.quantity,
      unit: entity.unit,
      isCompleted: entity.isCompleted,
      notes: entity.notes,
      desiredAttributes: entity.desiredAttributes,
    );
    // Relationships are handled separately
    return model;
  }

  ShoppingItem toEntity() {
    return ShoppingItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      isCompleted: isCompleted,
      notes: notes,
      desiredAttributes: desiredAttributes,
      preferredVariant: preferredVariant.target?.toEntity(),
      groceryStores:
          groceryStores.map((storeModel) => storeModel.toEntity()).toList(),
    );
  }
}
