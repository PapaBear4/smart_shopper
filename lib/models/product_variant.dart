import 'package:objectbox/objectbox.dart';
import 'brand.dart'; // For ToOne<Brand>

@Entity()
class ProductVariant {
  @Id()
  int id = 0;

  String name; // Full descriptive name, e.g., "Welch's Grape Jelly 12oz"
  String baseProductName; // General name, e.g., "Jelly", "Peanut Butter"
  String? upcCode; // Universal Product Code

  // General Product Characteristics
  String? form; // e.g., "Sliced", "Whole", "Diced", "Powder", "Liquid"
  String? packageSize; // e.g., "12oz", "500g", "Large"
  String? containerType; // e.g., "Bottle", "Can", "Jar", "Box", "Bag"
  String? preparation; // e.g., "Ready-to-eat", "Cook & Serve", "Frozen"
  String? maturity; // for produce, e.g., "Ripe", "Green"
  String? grade; // for meats, eggs, e.g., "Grade A", "Choice"

  // Dietary & Health Attributes
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
  List<String> allergenInfo = []; // e.g., ["Contains Peanuts"]

  // Flavor & Ingredient Specifics
  String? flavor;
  String? scent;
  String? color;
  String? mainIngredient;
  List<String> secondaryIngredients = [];
  String? spicinessLevel; // e.g., "Mild", "Medium", "Hot"
  String? caffeineContent; // e.g., "Caffeinated", "Decaf"
  String? alcoholContent; // e.g., "5% ABV", "Non-alcoholic"

  // Brand & Product Line
  String? subBrand;
  String? productLine;

  List<String> customAttributes = []; // For other dynamic attributes

  final brand = ToOne<Brand>();

  ProductVariant({
    this.id = 0,
    required this.name,
    required this.baseProductName,
    this.flavor,
    this.packageSize,
    this.isOrganic = false,
    this.isGlutenFree = false,
    this.upcCode,
    this.form,
    this.containerType,
    this.preparation,
    this.maturity,
    this.grade,
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
    this.scent,
    this.color,
    this.mainIngredient,
    List<String>? secondaryIngredients,
    this.spicinessLevel,
    this.caffeineContent,
    this.alcoholContent,
    this.subBrand,
    this.productLine,
    List<String>? customAttributes,
  }) : this.customAttributes = customAttributes ?? [],
       this.allergenInfo = allergenInfo ?? [],
       this.secondaryIngredients = secondaryIngredients ?? [];
}
