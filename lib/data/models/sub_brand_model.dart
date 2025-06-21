import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/brand_model.dart';
import 'package:smart_shopper/domain/entities/sub_brand.dart' as domain;

@Entity()
class SubBrandModel {
  @Id()
  int id = 0;

  String name;

  final brand = ToOne<BrandModel>();

  SubBrandModel({
    this.id = 0,
    required this.name,
  });

  domain.SubBrand toEntity() {
    return domain.SubBrand(
      id: id,
      name: name,
      brandId: brand.targetId,
    );
  }

  static SubBrandModel fromEntity(domain.SubBrand entity) {
    return SubBrandModel(
      id: entity.id,
      name: entity.name,
    )..brand.targetId = entity.brandId;
  }
}
