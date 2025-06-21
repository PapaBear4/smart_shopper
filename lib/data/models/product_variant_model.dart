import 'package:objectbox/objectbox.dart';
import 'package:smart_shopper/data/models/brand_model.dart';
import 'package:smart_shopper/data/models/price_entry_model.dart';
import 'package:smart_shopper/data/models/product_line_model.dart';
import 'package:smart_shopper/data/models/sub_brand_model.dart';
import 'package:smart_shopper/domain/entities/product_variant.dart';

@Entity()
class ProductVariantModel {
  @Id()
  int id = 0;

  String name;
  String baseProductName;
  String? upcCode;
  String? form;
  double? packagedQuantity;
  String? packagedUnit;
  String? displayPackageSize;
  String? containerType;
  String? preparation;
  String? maturity;
  String? grade;
  bool isOrganic = false;
  bool isGlutenFree = false;
  bool isNonGMO = false;
  bool isVegan = false;
  bool isVegetarian = false;
  bool isDairyFree = false;
  bool isNutFree = false;
  bool isSoyFree = false;
  bool isKosher = false;
  bool isHalal = false;
  bool isSugarFree = false;
  bool isLowSodium = false;
  bool isLowFat = false;
  bool isLowCarb = false;
  bool isHighProtein = false;
  bool isWholeGrain = false;
  bool hasNoAddedSugar = false;
  bool hasArtificialSweeteners = false;
  List<String> allergenInfo = [];
  String? flavor;
  String? scent;
  String? color;
  String? mainIngredient;
  List<String> secondaryIngredients = [];
  String? spicinessLevel;
  String? caffeineContent;
  String? alcoholContent;
  List<String> customAttributes = [];

  final brand = ToOne<BrandModel>();
  final subBrand = ToOne<SubBrandModel>();
  final productLine = ToOne<ProductLineModel>();

  @Backlink('productVariant')
  final priceEntries = ToMany<PriceEntryModel>();

  ProductVariantModel({
    this.id = 0,
    required this.name,
    required this.baseProductName,
    this.upcCode,
    this.form,
    this.packagedQuantity,
    this.packagedUnit,
    this.displayPackageSize,
    this.containerType,
    this.preparation,
    this.maturity,
    this.grade,
    this.isOrganic = false,
    this.isGlutenFree = false,
    this.isNonGMO = false,
    this.isVegan = false,
    this.isVegetarian = false,
    this.isDairyFree = false,
    this.isNutFree = false,
    this.isSoyFree = false,
    this.isKosher = false,
    this.isHalal = false,
    this.isSugarFree = false,
    this.isLowSodium = false,
    this.isLowFat = false,
    this.isLowCarb = false,
    this.isHighProtein = false,
    this.isWholeGrain = false,
    this.hasNoAddedSugar = false,
    this.hasArtificialSweeteners = false,
    List<String>? allergenInfo,
    this.flavor,
    this.scent,
    this.color,
    this.mainIngredient,
    List<String>? secondaryIngredients,
    this.spicinessLevel,
    this.caffeineContent,
    this.alcoholContent,
    List<String>? customAttributes,
  })  : allergenInfo = allergenInfo ?? [],
        secondaryIngredients = secondaryIngredients ?? [],
        customAttributes = customAttributes ?? [];

  ProductVariant toEntity() {
    if (brand.target == null) {
      throw StateError('Brand relation is not set for ProductVariantModel id: $id');
    }
    return ProductVariant(
      id: id,
      name: name,
      baseProductName: baseProductName,
      brand: brand.target!.toEntity(),
      subBrand: subBrand.target?.toEntity(),
      productLine: productLine.target?.toEntity(),
      upcCode: upcCode,
      form: form,
      packagedQuantity: packagedQuantity,
      packagedUnit: packagedUnit,
      displayPackageSize: displayPackageSize,
      containerType: containerType,
      preparation: preparation,
      maturity: maturity,
      grade: grade,
      isOrganic: isOrganic,
      isGlutenFree: isGlutenFree,
      isNonGMO: isNonGMO,
      isVegan: isVegan,
      isVegetarian: isVegetarian,
      isDairyFree: isDairyFree,
      isNutFree: isNutFree,
      isSoyFree: isSoyFree,
      isKosher: isKosher,
      isHalal: isHalal,
      isSugarFree: isSugarFree,
      isLowSodium: isLowSodium,
      isLowFat: isLowFat,
      isLowCarb: isLowCarb,
      isHighProtein: isHighProtein,
      isWholeGrain: isWholeGrain,
      hasNoAddedSugar: hasNoAddedSugar,
      hasArtificialSweeteners: hasArtificialSweeteners,
      allergenInfo: allergenInfo,
      flavor: flavor,
      scent: scent,
      color: color,
      mainIngredient: mainIngredient,
      secondaryIngredients: secondaryIngredients,
      spicinessLevel: spicinessLevel,
      caffeineContent: caffeineContent,
      alcoholContent: alcoholContent,
      customAttributes: customAttributes,
    );
  }

  static ProductVariantModel fromEntity(ProductVariant entity) {
    final model = ProductVariantModel(
      id: entity.id,
      name: entity.name,
      baseProductName: entity.baseProductName,
      upcCode: entity.upcCode,
      form: entity.form,
      packagedQuantity: entity.packagedQuantity,
      packagedUnit: entity.packagedUnit,
      displayPackageSize: entity.displayPackageSize,
      containerType: entity.containerType,
      preparation: entity.preparation,
      maturity: entity.maturity,
      grade: entity.grade,
      isOrganic: entity.isOrganic,
      isGlutenFree: entity.isGlutenFree,
      isNonGMO: entity.isNonGMO,
      isVegan: entity.isVegan,
      isVegetarian: entity.isVegetarian,
      isDairyFree: entity.isDairyFree,
      isNutFree: entity.isNutFree,
      isSoyFree: entity.isSoyFree,
      isKosher: entity.isKosher,
      isHalal: entity.isHalal,
      isSugarFree: entity.isSugarFree,
      isLowSodium: entity.isLowSodium,
      isLowFat: entity.isLowFat,
      isLowCarb: entity.isLowCarb,
      isHighProtein: entity.isHighProtein,
      isWholeGrain: entity.isWholeGrain,
      hasNoAddedSugar: entity.hasNoAddedSugar,
      hasArtificialSweeteners: entity.hasArtificialSweeteners,
      allergenInfo: entity.allergenInfo,
      flavor: entity.flavor,
      scent: entity.scent,
      color: entity.color,
      mainIngredient: entity.mainIngredient,
      secondaryIngredients: entity.secondaryIngredients,
      spicinessLevel: entity.spicinessLevel,
      caffeineContent: entity.caffeineContent,
      alcoholContent: entity.alcoholContent,
      customAttributes: entity.customAttributes,
    );

    model.brand.target = BrandModel.fromEntity(entity.brand);
    if (entity.subBrand != null) {
      model.subBrand.target = SubBrandModel.fromEntity(entity.subBrand!);
    }
    if (entity.productLine != null) {
      model.productLine.target = ProductLineModel.fromEntity(entity.productLine!);
    }

    return model;
  }
}
