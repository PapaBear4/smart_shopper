// This imports the generated file that contains the openStore() function
// and entity model definitions for ObjectBox.
import 'objectbox.g.dart';
import 'package:smart_shopper/data/models/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// A helper class to manage the ObjectBox store and provide access to entity boxes.
class ObjectBoxHelper {
  /// The ObjectBox store instance.
  late final Store _store;

  /// Public getter for the store.
  Store get store => _store;

  // Declare Box instances for each of your entities.
  // These will be initialized in the _create private constructor.
  late final Box<BrandModel> brandBox;
  late final Box<SubBrandModel> subBrandBox;
  late final Box<ProductLineModel> productLineBox;
  late final Box<PriceEntryModel> priceEntryBox;
  late final Box<GroceryStoreModel> groceryStoreBox;
  late final Box<ShoppingItemModel> shoppingItemBox;
  late final Box<ShoppingListModel> shoppingListBox;
  late final Box<ProductVariantModel> productVariantBox; // Added

  /// Private constructor to initialize the store and boxes.
  /// This is called by the static `create` method.
  ObjectBoxHelper._create(this._store) {
    // Initialize all your entity boxes here
    brandBox = _store.box<BrandModel>();
    priceEntryBox = _store.box<PriceEntryModel>();
    groceryStoreBox = _store.box<GroceryStoreModel>();
    shoppingItemBox = _store.box<ShoppingItemModel>();
    shoppingListBox = _store.box<ShoppingListModel>();
    productVariantBox = _store.box<ProductVariantModel>(); // Added
    subBrandBox = _store.box<SubBrandModel>();
    productLineBox = _store.box<ProductLineModel>();
  }

  /// Creates and initializes an ObjectBoxHelper instance.
  ///
  /// This static method should be called once at app startup (e.g., in main.dart)
  /// to set up the database.
  static Future<ObjectBoxHelper> create() async {
    // This is the correct way to do it:
    // 1. Get the application documents directory.
    final docsDir = await getApplicationDocumentsDirectory();
    // 2. Join the path with your database name.
    final storePath = p.join(docsDir.path, "smart_shopper_db");
    // 3. Open the store at that path.
    final store = await openStore(directory: storePath);
    // 4. Create the helper instance with the opened store.
    return ObjectBoxHelper._create(store);
  }

  /// Clears all data from all entity boxes.
  Future<void> clearAllData() async {
    // It's good practice to run this in a write transaction
    // if multiple boxes are being cleared, though removeAll() on each box
    // is usually transactional itself.
    // For simplicity and clarity, we'll clear them one by one.
    // The order typically doesn't matter unless there are specific
    // inter-dependencies you need to manage manually (rare).
    await brandBox.removeAllAsync();
    await priceEntryBox.removeAllAsync();
    await shoppingItemBox
        .removeAllAsync(); // Clear items before lists if items have relations to lists
    await shoppingListBox.removeAllAsync();
    await groceryStoreBox
        .removeAllAsync(); // Clear stores last if other entities relate to them
    await productVariantBox.removeAllAsync(); // Added
    await subBrandBox.removeAllAsync();
    await productLineBox.removeAllAsync();

    // Alternatively, ObjectBox provides a way to delete all objects of all types,
    // but it's often safer to be explicit if you want to ensure specific order
    // or if you might not want to clear *everything* in the future.
    // Example: _store.removeAllObjects(); (This is a more direct way)
    // For this helper, explicit removal is fine.
  }

  /// Closes the ObjectBox store.
  void dispose() {
    _store.close();
  }
}
