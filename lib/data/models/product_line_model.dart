import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/brand_model.dart';
import 'package:smart_shopper/domain/entities/product_line.dart' as domain;

@Entity()
class ProductLineModel {
  @Id()
  int id = 0;

  String name;

  final brand = ToOne<BrandModel>();

  ProductLineModel({
    this.id = 0,
    required this.name,
  });

  domain.ProductLine toEntity() {
    return domain.ProductLine(
      id: id,
      name: name,
      brandId: brand.targetId,
    );
  }

  static ProductLineModel fromEntity(domain.ProductLine entity) {
    return ProductLineModel(
      id: entity.id,
      name: entity.name,
    )..brand.targetId = entity.brandId;
  }
}
