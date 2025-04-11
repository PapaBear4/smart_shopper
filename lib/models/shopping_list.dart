import 'package:objectbox/objectbox.dart';
import 'shopping_item.dart'; // Import needed for the relationship

@Entity()
class ShoppingList {
  @Id()
  int id = 0;

  String name;

  // Establishes a one-to-many relationship with ShoppingItem
  // '@Backlink()' specifies the ToOne field in ShoppingItem that points back to this ShoppingList
  @Backlink('shoppingList')
  final items = ToMany<ShoppingItem>();

  ShoppingList({
    this.id = 0,
    required this.name,
  });
}