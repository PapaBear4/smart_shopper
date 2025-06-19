import 'package:objectbox/objectbox.dart';
import 'brand.dart'; // For ToOne<Brand>
import 'shopping_list.dart'; // Import for ToMany<ShoppingList>
import 'price_entry.dart'; // Import for ToMany<PriceEntry>
import 'grocery_store.dart'; // Import for ToMany<GroceryStore>

/// Represents a specific version or variant of a product.
///
/// For example, "Welch's Grape Jelly 12oz" is a specific variant of the
/// base product "Jelly". This class captures detailed attributes of a product
/// beyond its general name, including size, packaging, dietary information, etc.
@Entity()
class ProductVariant {
  /// The unique identifier for the product variant.
  /// This is automatically assigned by ObjectBox.
  @Id()
  int id = 0;

  /// The full descriptive name of the product variant (e.g., "Welch's Grape Jelly 12oz").
  String name;

  /// The general or base name of the product (e.g., "Jelly", "Peanut Butter").
  /// This helps in grouping similar variants.
  String baseProductName;

  /// The Universal Product Code (UPC) of the variant, if available
  // TODO: Consider adding EAN-13 or other barcode formats (and business logic)
  String? upcCode;

  // General Product Characteristics
  /// The form of the product (e.g., "Sliced", "Whole", "Diced", "Powder", "Liquid").
  String? form;

  /// The numeric quantity of the product in this package, used for calculations (e.g., 340.0 for 340g).
  double? packagedQuantity;
  /// The standardized unit for packagedQuantity (e.g., "g", "ml", "oz_fl", "oz_wt", "count").
  String? packagedUnit;
  /// A user-friendly string describing the package size (e.g., "12oz (340g)", "6-pack", "Family Size").
  /// This is primarily for display purposes.
  String? displayPackageSize;

  /// The type of container (e.g., "Bottle", "Can", "Jar", "Box", "Bag").
  String? containerType;
  /// Preparation instructions or type (e.g., "Ready-to-eat", "Cook & Serve", "Frozen").
  String? preparation;
  /// Maturity level, typically for produce (e.g., "Ripe", "Green").
  String? maturity;
  /// Grade or quality, often for meats or eggs (e.g., "Grade A", "Choice").
  String? grade;

  // Dietary & Health Attributes
  /// Indicates if the product is certified organic. Defaults to `false`.
  bool isOrganic = false;
  /// Indicates if the product is gluten-free. Defaults to `false`.
  bool isGlutenFree = false;
  /// Indicates if the product is non-GMO. Defaults to `false`.
  bool isNonGMO = false;
  /// Indicates if the product is vegan. Defaults to `false`.
  bool isVegan = false;
  /// Indicates if the product is vegetarian. Defaults to `false`.
  bool isVegetarian = false;
  /// Indicates if the product is dairy-free. Defaults to `false`.
  bool isDairyFree = false;
  /// Indicates if the product is nut-free. Defaults to `false`.
  bool isNutFree = false;
  /// Indicates if the product is soy-free. Defaults to `false`.
  bool isSoyFree = false;
  /// Indicates if the product is kosher. Defaults to `false`.
  bool isKosher = false;
  /// Indicates if the product is halal. Defaults to `false`.
  bool isHalal = false;
  /// Indicates if the product is sugar-free. Defaults to `false`.
  bool isSugarFree = false;
  /// Indicates if the product is low in sodium. Defaults to `false`.
  bool isLowSodium = false;
  /// Indicates if the product is low in fat. Defaults to `false`.
  bool isLowFat = false;
  /// Indicates if the product is low in carbohydrates. Defaults to `false`.
  bool isLowCarb = false;
  /// Indicates if the product is high in protein. Defaults to `false`.
  bool isHighProtein = false;
  /// Indicates if the product is whole grain. Defaults to `false`.
  bool isWholeGrain = false;
  /// Indicates if the product has no added sugar. Defaults to `false`.
  bool hasNoAddedSugar = false;
  /// Indicates if the product contains artificial sweeteners. Defaults to `false`.
  bool hasArtificialSweeteners = false;
  /// A list of allergen information strings (e.g., ["Contains Peanuts"]).

  List<String> allergenInfo = [];

  // Flavor & Ingredient Specifics
  /// The primary flavor of the product (e.g., "Grape", "Strawberry").
  String? flavor;
  /// The primary scent of the product, if applicable.
  String? scent;
  /// The color of the product, if relevant.
  String? color;
  /// The main ingredient of the product.
  String? mainIngredient;
  /// A list of secondary or notable ingredients.
  List<String> secondaryIngredients = [];
  /// The spiciness level, if applicable (e.g., "Mild", "Medium", "Hot").
  String? spicinessLevel;
  /// Caffeine content information (e.g., "Caffeinated", "Decaf").
  String? caffeineContent;
  /// Alcohol content information (e.g., "5% ABV", "Non-alcoholic").
  String? alcoholContent;

  // Brand & Product Line
  /// A sub-brand name, if applicable (e.g., "Diet Coke" under "Coca-Cola").
  String? subBrand;
  /// The specific product line this variant belongs to.
  String? productLine;

  /// A list for any other dynamic or custom attributes not covered by specific fields.
  List<String> customAttributes = [];

  /// A link to the [Brand] of this product variant.
  final brand = ToOne<Brand>();

  /// A list of shopping lists that this product variant is part of.
  /// This establishes the non-owning side of a many-to-many relationship
  /// with [ShoppingList]. The `Backlink` annotation refers to the
  /// `productVariants` field in the [ShoppingList] entity.
  @Backlink('productVariants')
  final shoppingLists = ToMany<ShoppingList>();

  /// A list of price entries associated with this product variant.
  /// This establishes a one-to-many relationship, where one product variant
  /// can have multiple price history records.
  /// The `Backlink` annotation refers to the `productVariant` field in the
  /// [PriceEntry] entity.
  @Backlink('productVariant')
  final priceEntries = ToMany<PriceEntry>();

  /// A list of grocery stores where this product variant is available.
  /// This establishes the non-owning side of a many-to-many relationship
  /// with [GroceryStore]. The `Backlink` annotation refers to the
  /// `carriedProductVariants` field in the [GroceryStore] entity.
  @Backlink('carriedProductVariants')
  final availableInStores = ToMany<GroceryStore>();

  /// Creates a new [ProductVariant] instance.
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// [name] (full descriptive name) and [baseProductName] are required.
  /// All other fields are optional and can be provided to specify the variant's characteristics.
  /// List fields like [allergenInfo], [secondaryIngredients], and [customAttributes]
  /// default to empty lists if not provided.
  ProductVariant({
    this.id = 0,
    required this.name,
    required this.baseProductName,
    this.flavor,
    this.packagedQuantity,
    this.packagedUnit,
    this.displayPackageSize,
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
  }) : customAttributes = customAttributes ?? [],
       allergenInfo = allergenInfo ?? [],
       secondaryIngredients = secondaryIngredients ?? [];

  /// Converts this [ProductVariant] instance to a JSON map.
  /// Useful for debugging, logging, or serialization.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseProductName': baseProductName,
        'upcCode': upcCode,
        'form': form,
        'packagedQuantity': packagedQuantity,
        'packagedUnit': packagedUnit,
        'displayPackageSize': displayPackageSize,
        'containerType': containerType,
        'preparation': preparation,
        'maturity': maturity,
        'grade': grade,
        'isOrganic': isOrganic,
        'isGlutenFree': isGlutenFree,
        'isNonGMO': isNonGMO,
        'isVegan': isVegan,
        'isVegetarian': isVegetarian,
        'isDairyFree': isDairyFree,
        'isNutFree': isNutFree,
        'isSoyFree': isSoyFree,
        'isKosher': isKosher,
        'isHalal': isHalal,
        'isSugarFree': isSugarFree,
        'isLowSodium': isLowSodium,
        'isLowFat': isLowFat,
        'isLowCarb': isLowCarb,
        'isHighProtein': isHighProtein,
        'isWholeGrain': isWholeGrain,
        'hasNoAddedSugar': hasNoAddedSugar,
        'hasArtificialSweeteners': hasArtificialSweeteners,
        'allergenInfo': allergenInfo,
        'flavor': flavor,
        'scent': scent,
        'color': color,
        'mainIngredient': mainIngredient,
        'secondaryIngredients': secondaryIngredients,
        'spicinessLevel': spicinessLevel,
        'caffeineContent': caffeineContent,
        'alcoholContent': alcoholContent,
        'subBrand': subBrand,
        'productLine': productLine,
        'customAttributes': customAttributes,
        'brand': brand.target?.id, // Log brand ID if exists
        'shoppingLists': shoppingLists.map((sl) => sl.id).toList(), // Log shopping list IDs
        'priceEntries': priceEntries.map((pe) => pe.id).toList(), // Log price entry IDs
        'availableInStores': availableInStores.map((gs) => gs.id).toList(), // Log grocery store IDs
      };

  /// Returns a string representation of the [ProductVariant].
  /// Useful for debugging and logging.
  @override
  String toString() {
    return 'ProductVariant{id: $id, name: "$name", baseProductName: "$baseProductName", brand: ${brand.target?.name ?? "N/A"}, size: "${displayPackageSize ?? (packagedQuantity?.toString() ?? packagedUnit ?? "")}"}';
  }
}
