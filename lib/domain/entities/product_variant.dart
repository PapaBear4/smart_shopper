import 'package:equatable/equatable.dart';
import 'package:smart_shopper/domain/entities/brand.dart';
import 'package:smart_shopper/domain/entities/product_line.dart';
import 'package:smart_shopper/domain/entities/sub_brand.dart';

/// Represents a specific version or variant of a product.
class ProductVariant extends Equatable {
  final int id;
  final String name;
  final String baseProductName;

  // TODO: Consider expanding to support other barcode formats like EAN-13.
  final String? upcCode;

  // General Product Characteristics
  final String? form; // e.g., "solid", "liquid", "powder", etc.
  final double? packagedQuantity; // e.g., 500, 1.5, etc.
  final String? packagedUnit; //e.g., "g", "kg", "L", "mL", etc.
  final String? displayPackageSize; //e.g., "500g", "1L", etc.
  final String? containerType; //bottle, box, can, etc.
  final String? preparation; //frozen, fresh, dried, etc.
  final String? maturity; //ripe, unripe, etc.
  final String? grade; //e.g., "A", "B", etc. for quality grading

  // Dietary & Health Attributes
  final bool isOrganic;
  final bool isGlutenFree;
  final bool isNonGMO;
  final bool isVegan;
  final bool isVegetarian;
  final bool isDairyFree;
  final bool isNutFree;
  final bool isSoyFree;
  final bool isKosher;
  final bool isHalal;
  final bool isSugarFree;
  final bool isLowSodium;
  final bool isLowFat;
  final bool isLowCarb;
  final bool isHighProtein;
  final bool isWholeGrain;
  final bool hasNoAddedSugar;
  final bool hasArtificialSweeteners;
  final List<String> allergenInfo;

  // Flavor & Ingredient Specifics
  final String? flavor;
  final String? scent;
  final String? color;
  final String? mainIngredient;
  final List<String> secondaryIngredients;
  final String? spicinessLevel;
  final String? caffeineContent;
  final String? alcoholContent;

  // Brand & Product Line
  final Brand brand;
  final SubBrand? subBrand;
  final ProductLine? productLine;

  final List<String> customAttributes;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.baseProductName,
    required this.brand,
    this.subBrand,
    this.productLine,
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
    this.allergenInfo = const [],
    this.flavor,
    this.scent,
    this.color,
    this.mainIngredient,
    this.secondaryIngredients = const [],
    this.spicinessLevel,
    this.caffeineContent,
    this.alcoholContent,
    this.customAttributes = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    baseProductName,
    upcCode,
    form,
    packagedQuantity,
    packagedUnit,
    displayPackageSize,
    containerType,
    preparation,
    maturity,
    grade,
    isOrganic,
    isGlutenFree,
    isNonGMO,
    isVegan,
    isVegetarian,
    isDairyFree,
    isNutFree,
    isSoyFree,
    isKosher,
    isHalal,
    isSugarFree,
    isLowSodium,
    isLowFat,
    isLowCarb,
    isHighProtein,
    isWholeGrain,
    hasNoAddedSugar,
    hasArtificialSweeteners,
    allergenInfo,
    flavor,
    scent,
    color,
    mainIngredient,
    secondaryIngredients,
    spicinessLevel,
    caffeineContent,
    alcoholContent,
    customAttributes,
    brand,
    subBrand,
    productLine,
  ];
}
