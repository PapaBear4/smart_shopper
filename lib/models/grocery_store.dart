//lib/models/grocery_store.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class GroceryStore {
  @Id()
  int id = 0;

  String name; // Non-nullable, must be initialized
  String? website;
  String? address;
  String? phoneNumber;

  // Corrected constructor name to match the class name 'GroceryStore'
  GroceryStore({
    this.id = 0,
    required this.name, // 'required' ensures 'name' is provided and initialized
    this.website,
    this.address,
    this.phoneNumber,
  });
}