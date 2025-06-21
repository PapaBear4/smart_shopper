import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/brand_model.dart';
import 'package:smart_shopper/data/models/price_entry_model.dart';
import 'package:smart_shopper/domain/entities/grocery_store.dart';

@Entity()
class GroceryStoreModel {
  @Id()
  int id = 0;

  String name;
  String? website;
  String? address;
  String? phoneNumber;
  String? storeNumber;

  final brands = ToMany<BrandModel>();

  @Backlink('groceryStore')
  final priceEntries = ToMany<PriceEntryModel>();

  GroceryStoreModel({
    this.id = 0,
    required this.name,
    this.website,
    this.address,
    this.phoneNumber,
    this.storeNumber,
  });

  GroceryStore toEntity() {
    return GroceryStore(
      id: id,
      name: name,
      website: website,
      address: address,
      phoneNumber: phoneNumber,
      storeNumber: storeNumber,
      brands: brands.map((model) => model.toEntity()).toList(),
    );
  }

  static GroceryStoreModel fromEntity(GroceryStore entity) {
    final model = GroceryStoreModel(
      id: entity.id,
      name: entity.name,
      website: entity.website,
      address: entity.address,
      phoneNumber: entity.phoneNumber,
      storeNumber: entity.storeNumber,
    );
    // Note: This assumes the relationships are managed elsewhere,
    // as we can't directly convert a List<Brand> to a ToMany<BrandModel> here.
    return model;
  }
}
