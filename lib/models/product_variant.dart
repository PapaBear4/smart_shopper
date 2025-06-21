// Import the ObjectBox library for database entity annotations.
import 'package:objectbox/objectbox.dart';

// Import related model classes to define relationships.
import '../domain/entities/brand.dart'; // Required for the ToOne<Brand> relationship.
import 'shopping_list.dart'; // Required for the ToMany<ShoppingList> backlink.
import 'price_entry.dart'; // Required for the ToMany<PriceEntry> backlink.
import 'grocery_store.dart'; // Required for the ToMany<GroceryStore> backlink.

/// Represents a specific version or variant of a product.
///
/// This class is an ObjectBox `@Entity`, meaning it's a persistable object in the database.
/// It's designed to capture the detailed attributes of a product beyond its general name.
/// For instance, "Welch's Grape Jelly 12oz" would be a `ProductVariant` of the
/// base product "Jelly". This allows for precise tracking of different sizes,
/// flavors, packaging, and dietary characteristics.
@Entity()
class ProductVariant {
  /// The unique identifier for this product variant in the ObjectBox database.
  /// The `@Id()` annotation marks this as the primary key.
  /// It is automatically assigned and managed by ObjectBox when a new variant is added.
  @Id()
  int id = 0;

  /// The full, descriptive name of the product variant.
  /// This should be specific enough to distinguish it from other variants.
  /// Example: "Welch's Concord Grape Jelly Squeezable Bottle".
  String name;

  /// The general or base category name of the product.
  /// This field is useful for grouping similar variants together.
  /// Example: "Jelly", "Peanut Butter", "Soda".
  String baseProductName;

  /// The Universal Product Code (UPC) for this specific variant.
  /// This is often a scannable barcode number. It is nullable as not all products may have one.
  // TODO: Consider expanding to support other barcode formats like EAN-13 and adding related business logic.
  String? upcCode;

  // --- General Product Characteristics ---

  /// Describes the physical form of the product.
  /// Example: "Sliced", "Whole", "Diced", "Powder", "Liquid".
  String? form;

  /// The numeric quantity of the product contained in the package.
  /// This should be used for precise calculations and comparisons.
  /// Example: 340.0 (for 340g).
  double? packagedQuantity;

  /// The standardized unit of measurement for the `packagedQuantity`.
  /// Using a consistent set of units is recommended (e.g., "g", "ml", "oz_fl", "oz_wt", "count").
  String? packagedUnit;

  /// A user-friendly string that describes the package size.
  /// This is primarily intended for display in the user interface.
  /// Example: "12oz (340g)", "6-pack", "Family Size".
  String? displayPackageSize;

  /// The type of container the product comes in.
  /// Example: "Bottle", "Can", "Jar", "Box", "Bag".
  String? containerType;

  /// Instructions or type of preparation required.
  /// Example: "Ready-to-eat", "Cook & Serve", "Frozen".
  String? preparation;

  /// The maturity level, typically used for fresh produce.
  /// Example: "Ripe", "Green".
  String? maturity;

  /// The quality grade, often used for products like meat or eggs.
  /// Example: "Grade A", "USDA Choice".
  String? grade;

  // --- Dietary & Health Attributes ---
  // These boolean flags help users filter products based on dietary needs.

  /// Indicates if the product is certified organic. Defaults to `false`.
  bool isOrganic = false;
  /// Indicates if the product is gluten-free. Defaults to `false`.
  bool isGlutenFree = false;
  /// Indicates if the product is non-GMO. Defaults to `false`.
  bool isNonGMO = false;
  /// Indicates if the product is suitable for vegans. Defaults to `false`.
  bool isVegan = false;
  /// Indicates if the product is suitable for vegetarians. Defaults to `false`.
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
  /// Indicates if the product is made with whole grain. Defaults to `false`.
  bool isWholeGrain = false;
  /// Indicates if the product has no added sugar. Defaults to `false`.
  bool hasNoAddedSugar = false;
  /// Indicates if the product contains artificial sweeteners. Defaults to `false`.
  bool hasArtificialSweeteners = false;

  /// A list of strings containing allergen information.
  /// Example: ["Contains Peanuts", "Processed in a facility with tree nuts"].
  List<String> allergenInfo = [];

  // --- Flavor & Ingredient Specifics ---

  /// The primary flavor of the product.
  /// Example: "Grape", "Strawberry", "Original".
  String? flavor;
  /// The primary scent of the product, if applicable (e.g., for cleaning supplies).
  String? scent;
  /// The color of the product, if it's a relevant attribute.
  String? color;
  /// The main ingredient of the product.
  String? mainIngredient;
  /// A list of secondary or otherwise notable ingredients.
  List<String> secondaryIngredients = [];
  /// The level of spiciness, if applicable.
  /// Example: "Mild", "Medium", "Hot", "Extra Hot".
  String? spicinessLevel;
  /// Information about caffeine content.
  /// Example: "Caffeinated", "Decaffeinated".
  String? caffeineContent;
  /// Information about alcohol content.
  /// Example: "5% ABV", "Non-alcoholic".
  String? alcoholContent;

  // --- Brand & Product Line ---

  /// A sub-brand name, which is more specific than the main brand.
  /// Example: "Diet Coke" is a sub-brand of "Coca-Cola".
  String? subBrand;
  /// The specific product line this variant belongs to within a brand.
  /// Example: "Artisan" line of crackers.
  String? productLine;

  /// A list for any other dynamic or custom attributes that are not covered by the specific fields above.
  /// This provides flexibility to add ad-hoc information.
  List<String> customAttributes = [];

  // --- ObjectBox Relationships ---

  /// A `ToOne` relationship linking this variant to its [Brand].
  /// This represents the "owning" side of the one-to-one or one-to-many relationship.
  final brand = ToOne<Brand>();

  /// A `ToMany` backlink to [ShoppingList] entities that include this variant.
  /// The `@Backlink` annotation indicates that this is the non-owning side of a
  /// many-to-many relationship, managed via the `productVariants` field in the [ShoppingList] class.
  @Backlink('productVariants')
  final shoppingLists = ToMany<ShoppingList>();

  /// A `ToMany` backlink to [PriceEntry] entities associated with this variant.
  /// This creates a one-to-many relationship, allowing one product variant to have a history of many price entries.
  /// The `Backlink` refers to the `productVariant` field in the [PriceEntry] class.
  @Backlink('productVariant')
  final priceEntries = ToMany<PriceEntry>();

  /// A `ToMany` backlink to [GroceryStore] entities where this variant is available.
  /// This establishes the non-owning side of a many-to-many relationship,
  /// managed via the `carriedProductVariants` field in the [GroceryStore] class.
  @Backlink('carriedProductVariants')
  final availableInStores = ToMany<GroceryStore>();

  /// Creates a new instance of [ProductVariant].
  ///
  /// The [id] is optional and defaults to 0; it will be assigned by ObjectBox upon saving.
  /// [name] (the full descriptive name) and [baseProductName] are required.
  /// All other fields are optional and can be provided to specify the variant's characteristics.
  /// List fields like [allergenInfo], [secondaryIngredients], and [customAttributes]
  /// are initialized to empty lists if not provided, preventing null reference errors.
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

  /// Converts this [ProductVariant] instance into a JSON map.
  /// This is useful for debugging, logging, or serializing the object to a format
  /// that can be easily read or transmitted.
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
        'brand': brand.target?.id, // Log brand ID if available
        'shoppingLists': shoppingLists.map((sl) => sl.id).toList(), // Log shopping list IDs
        'priceEntries': priceEntries.map((pe) => pe.id).toList(), // Log price entry IDs
        'availableInStores': availableInStores.map((gs) => gs.id).toList(), // Log grocery store IDs
      };

  /// Returns a concise string representation of the [ProductVariant].
  /// This is primarily used for debugging and logging purposes.
  @override
  String toString() {
    // Provides a clean, readable summary of the variant's key identifiers.
    return 'ProductVariant{id: $id, name: "$name", baseProductName: "$baseProductName", brand: ${brand.target?.name ?? "N/A"}, size: "${displayPackageSize ?? (packagedQuantity?.toString() ?? packagedUnit ?? "")}"}';
  }
}
