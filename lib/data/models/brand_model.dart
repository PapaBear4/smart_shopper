import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/domain/entities/brand.dart' as domain;
import '../../models/grocery_store.dart';
import 'sub_brand_model.dart';
import 'product_line_model.dart';

@Entity()
class BrandModel {
  @Id()
  int id = 0;

  String name;

  @Backlink('brands')
  final groceryStores = ToMany<GroceryStore>();

  @Backlink('brand')
  final subBrands = ToMany<SubBrandModel>();

  @Backlink('brand')
  final productLines = ToMany<ProductLineModel>();

  BrandModel({
    this.id = 0,
    required this.name,
  });

  domain.Brand toEntity() {
    return domain.Brand(
      id: id,
      name: name,
    );
  }

  static BrandModel fromEntity(domain.Brand entity) {
    return BrandModel(
      id: entity.id,
      name: entity.name,
    );
  }
}
