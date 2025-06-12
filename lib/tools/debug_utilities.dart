import 'package:faker_dart/faker_dart.dart';
import 'dart:math';
import 'package:smart_shopper/models/models.dart';
import 'package:smart_shopper/objectbox_helper.dart';
import 'package:smart_shopper/repositories/brand_repository.dart';
import 'package:smart_shopper/repositories/price_entry_repository.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/repositories/shopping_list_repository.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
import 'package:smart_shopper/repositories/product_variant_repository.dart';
import 'package:smart_shopper/service_locator.dart';
import 'package:smart_shopper/tools/logger.dart'; // Correct import for your logger
import 'package:smart_shopper/constants/app_constants.dart';

class DebugUtilities {
  static final faker = Faker.instance;
  static final _random = Random();

  static Future<void> generateTestData({
    int numShoppingLists = 3,
    int numItemsPerList = 5,
    int numStores = 4,
    int numBrands = 8,
    int priceEntriesPerProduct = 2,
    bool clearExistingData = true,
  }) async {
    logDebug('Starting test data generation...');

    if (clearExistingData) {
      await clearAppData();
    }

    final allStores = await _generateStores(numStores);
    final allBrands = await _generateBrands(numBrands);
    final allShoppingLists = await _generateShoppingLists(numShoppingLists);

    for (final list in allShoppingLists) {
      await _generateItemsForList(
        list,
        allBrands,
        allStores,
        numItemsPerList,
        priceEntriesPerProduct,
      );
    }
    logDebug('Test data generation complete.');
  }

  static Future<void> clearAppData() async { // Renamed from _clearAllData and made public
    logDebug('Clearing all data...');
    try {
      final objectBoxHelper = getIt<ObjectBoxHelper>();
      objectBoxHelper.priceEntryBox.removeAll();
      objectBoxHelper.shoppingItemBox.removeAll();
      objectBoxHelper.productVariantBox.removeAll();
      objectBoxHelper.brandBox.removeAll();
      objectBoxHelper.groceryStoreBox.removeAll();
      objectBoxHelper.shoppingListBox.removeAll();
      logDebug('All data cleared successfully.');
    } catch (e, s) {
      logError('Error clearing data: $e', e, s);
    }
  }

  static Future<List<GroceryStore>> _generateStores(int count) async {
    final storeRepo = getIt<IStoreRepository>();
    final List<GroceryStore> stores = [];
    for (int i = 0; i < count; i++) {
      final store = GroceryStore(
        name: faker.company.companyName() + " Mart",
        address: faker.address.streetAddress(),
        // latitude and longitude are not in the default GroceryStore model constructor
        // If your model has them, add them here: e.g. latitude: faker.address.latitude(),
      );
      final id = await storeRepo.addStore(store);
      store.id = id;
      stores.add(store);
    }
    logDebug('$count stores generated.');
    return stores;
  }

  static Future<List<Brand>> _generateBrands(int count) async {
    final brandRepo = getIt<IBrandRepository>();
    final List<Brand> brands = [];
    for (int i = 0; i < count; i++) {
      final brand = Brand(
        name: faker.company.companyName(),
      );
      final id = await brandRepo.addBrand(brand);
      brand.id = id;
      brands.add(brand);
    }
    logDebug('$count brands generated.');
    return brands;
  }

  static Future<List<ShoppingList>> _generateShoppingLists(int count) async {
    final listRepo = getIt<IShoppingListRepository>();
    final List<ShoppingList> lists = [];
    for (int i = 0; i < count; i++) {
      final list = ShoppingList(
        name: "${faker.commerce.department()} Shopping List",
        // createdDate removed as it's not in the model
        // description: _random.nextInt(100) < 30 ? faker.lorem.sentence() : null, // Example for optional field
      );
      final id = await listRepo.addList(list);
      list.id = id;
      lists.add(list);
    }
    logDebug('$count shopping lists generated.');
    return lists;
  }

  static Future<void> _generateItemsForList(
    ShoppingList list,
    List<Brand> allBrands,
    List<GroceryStore> allStores,
    int itemCount,
    int priceEntriesPerProduct,
  ) async {
    final itemRepo = getIt<IShoppingItemRepository>();
    final productVariantRepo = getIt<IProductVariantRepository>();

    logDebug('Generating $itemCount items for list ID: ${list.id} ("${list.name}")');

    for (int i = 0; i < itemCount; i++) {
      logDebug('List ${list.id} - Item loop ${i+1}/$itemCount');
      final ProductVariant productVariant = await _createAndSaveProductVariant(productVariantRepo, allBrands);
      logDebug('Created ProductVariant ID: ${productVariant.id}, Name: ${productVariant.name}');

      final ShoppingItem item = _createShoppingItem(list, productVariant);
      logDebug('Prepared ShoppingItem (before addItem): ${item.toJson()}');
      
      try {
        item.id = await itemRepo.addItem(item, list.id);
        logDebug('ShoppingItem after addItem. Returned ID: ${item.id}. Item JSON: ${item.toJson()}');
      } catch (e, s) {
        logError('Error in itemRepo.addItem for item "${item.name}": $e', e, s);
        continue; // Skip to next item if addItem fails
      }

      if (item.id == 0) {
        logError('itemRepo.addItem returned ID 0 for item "${item.name}". Skipping store assignment and update.');
      } else {
        if (allStores.isNotEmpty) {
          final numStoresForItem = _random.nextInt(min(3, allStores.length) + 1);
          final List<GroceryStore> selectedStores = List<GroceryStore>.from(allStores)..shuffle(_random);
          for (int j = 0; j < numStoresForItem; j++) {
            if (j < selectedStores.length) {
              item.groceryStores.add(selectedStores[j]);
            }
          }
          logDebug('ShoppingItem (before updateItem) ID: ${item.id}, Stores to add: ${item.groceryStores.map((s) => s.id).toList()}. Item JSON: ${item.toJson()}');
          try {
            await itemRepo.updateItem(item);
            logDebug('ShoppingItem after updateItem. ID: ${item.id}');
          } catch (e, s) {
            logError('Error in itemRepo.updateItem for item ID ${item.id}: $e', e, s);
          }
        } else {
          logDebug('No stores available to assign to item ID: ${item.id}');
        }
      }

      await _generatePriceEntries(productVariant, priceEntriesPerProduct, allStores);
    }
    logDebug('$itemCount items generation process completed for list "${list.name}".');
  }

  static Future<ProductVariant> _createAndSaveProductVariant(
      IProductVariantRepository repo, List<Brand> allBrands) async {
    final baseProductName = faker.commerce.productName();
    // Using inline lists as AppConstants might not have these yet
    final productForms = ['Whole', 'Sliced', 'Diced', 'Ground', 'Liquid', 'Powder', 'Spray', 'Bar'];
    final productContainerTypes = ['Bottle', 'Box', 'Can', 'Jar', 'Bag', 'Pack', 'Tube', 'Carton'];

    final productVariant = ProductVariant(
      name: "$baseProductName ${faker.commerce.productAdjective()} ${faker.commerce.productMaterial()}",
      baseProductName: baseProductName,
      upcCode: List.generate(12, (_) => _random.nextInt(10)).join(''), // Generate 12 random digits
      packageSize: "${faker.datatype.number(min: 1, max: 2000)}${_randomElement(['g', 'ml', 'oz', 'lb', 'kg', 'L', 'pcs'])}",
      form: _randomElement(productForms),
      containerType: _randomElement(productContainerTypes),
      flavor: _random.nextInt(100) < 50 ? faker.commerce.productAdjective() : null, // 50% chance of having a flavor
      isOrganic: _random.nextInt(100) < 20, // 20% chance
      isGlutenFree: _random.nextInt(100) < 15,
      isNonGMO: _random.nextInt(100) < 25,
      isVegan: _random.nextInt(100) < 10,
      isVegetarian: _random.nextInt(100) < 15,
      // Add more fields as per your ProductVariant model, e.g.:
      // isDairyFree: _random.nextInt(100) < 10,
      // isNutFree: _random.nextInt(100) < 5,
    );

    if (allBrands.isNotEmpty && _random.nextInt(100) < 75) { // 75% chance to have a brand
      productVariant.brand.target = allBrands[_random.nextInt(allBrands.length)];
    }
    
    productVariant.id = await repo.addProductVariant(productVariant);
    return productVariant;
  }

  static ShoppingItem _createShoppingItem(ShoppingList list, ProductVariant variant) {
    final item = ShoppingItem(
      name: variant.baseProductName, 
      quantity: faker.datatype.number(max: 5, min: 1).toDouble(),
      unit: AppConstants.predefinedUnits.isNotEmpty ? _randomElement(AppConstants.predefinedUnits) : 'pcs',
      category: faker.commerce.department(),
      isCompleted: _random.nextInt(100) < 10, // 10% chance
      notes: _random.nextInt(100) < 30 ? faker.lorem.sentence(wordCount: _random.nextInt(5) + 3) : null,
      desiredAttributes: List.generate(_random.nextInt(3), (_) => faker.commerce.productAdjective()),
    );
    item.shoppingList.target = list;
    item.preferredVariant.target = variant;
    return item;
  }

  static Future<void> _generatePriceEntries(
    ProductVariant productVariant,
    int count,
    List<GroceryStore> allStores,
  ) async {
    if (allStores.isEmpty || count == 0) return;

    final priceRepo = getIt<IPriceEntryRepository>();
    final now = DateTime(2025, 6, 11); // Current date as per user context

    for (int i = 0; i < count; i++) {
      final randomDaysToSubtract = _random.nextInt(90) + 1; // 1 to 90 days
      final entryDate = now.subtract(Duration(days: randomDaysToSubtract));

      final priceEntry = PriceEntry(
        price: faker.datatype.number(min: 50, max: 5000) / 100.0, // Price between 0.50 and 50.00
        date: entryDate,
      );
      priceEntry.productVariant.target = productVariant;
      priceEntry.groceryStore.target = allStores[_random.nextInt(allStores.length)];
      await priceRepo.addPriceEntry(priceEntry);
    }
  }

  // Helper to get a random element from a list
  static T _randomElement<T>(List<T> list) {
    if (list.isEmpty) throw ArgumentError('Cannot get a random element from an empty list.');
    return list[_random.nextInt(list.length)];
  }
}
