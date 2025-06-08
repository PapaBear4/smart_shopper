//lib/models/grocery_store.dart
import 'package:objectbox/objectbox.dart';
import 'brand.dart'; // Import for ToMany<Brand>

@Entity()
class GroceryStore {
  @Id()
  int id = 0;

  String name; // Non-nullable, must be initialized
  String? website;
  String? address;
  String? phoneNumber;

  // Establishes a many-to-many relationship with Brand
  final brands = ToMany<Brand>();

  // Corrected constructor name to match the class name 'GroceryStore'
  GroceryStore({
    this.id = 0,
    required this.name, // 'required' ensures 'name' is provided and initialized
    this.website,
    this.address,
    this.phoneNumber,
  });
}