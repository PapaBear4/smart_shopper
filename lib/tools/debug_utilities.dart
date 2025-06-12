import 'package:faker_dart/faker_dart.dart'; // Changed import to faker_dart
import 'dart:math'; // Import dart:math for Random
import 'package:smart_shopper/models/models.dart';
import 'package:smart_shopper/objectbox_helper.dart';
import 'package:smart_shopper/repositories/brand_repository.dart';
import 'package:smart_shopper/repositories/price_entry_repository.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/repositories/shopping_list_repository.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
import 'package:smart_shopper/repositories/product_variant_repository.dart'; // Added
import 'package:smart_shopper/service_locator.dart';
import 'package:smart_shopper/tools/logger.dart'; // Import the logger
import 'package:smart_shopper/constants/app_constants.dart'; // Import the new constants file

class DebugUtilities {
  static final faker = Faker.instance; // Changed to Faker.instance for faker_dart
  static final _random = Random(); // Create a Random instance for selections

  static Future<void> generateTestData({
    int numStores = 5,
    int numBrands = 8,
    int numLists = 5,
    int itemsPerList = 15,
    int priceEntriesPerItem = 5,
  }) async {
    await clearAppData();

    final stores = await _generateStores(numStores);
    final brands = await _generateBrands(numBrands);
    final lists = await _generateShoppingLists(numLists);

    for (final list in lists) {
      await _generateShoppingItems(list, itemsPerList, brands, stores, priceEntriesPerItem);
    }

    logInfo('Test data generated: $numStores stores, $numBrands brands, $numLists lists, ${numLists * itemsPerList} items, ${numLists * itemsPerList * priceEntriesPerItem} price entries.');
  }

  static Future<List<GroceryStore>> _generateStores(int count) async {
    final storeRepo = getIt<IStoreRepository>();
    final stores = <GroceryStore>[];
    for (int i = 0; i < count; i++) {
      final store = GroceryStore(
        name: faker.company.companyName(),
        address: faker.address.streetAddress(),
      );
      final id = await storeRepo.addStore(store);
      final fetchedStore = await storeRepo.getStoreById(id);
      if (fetchedStore != null) {
        stores.add(fetchedStore);
      }
    }
    return stores;
  }

  static Future<List<Brand>> _generateBrands(int count) async {
    final brandRepo = getIt<IBrandRepository>();
    final brands = <Brand>[];
    for (int i = 0; i < count; i++) {
      final brand = Brand(name: faker.company.companyName());
      final id = await brandRepo.addBrand(brand);
      final fetchedBrand = await brandRepo.getBrandById(id);
      if (fetchedBrand != null) {
        brands.add(fetchedBrand);
      }
    }
    return brands;
  }

  static Future<List<ShoppingList>> _generateShoppingLists(int count) async {
    final listRepo = getIt<IShoppingListRepository>();
    final lists = <ShoppingList>[];
    for (int i = 0; i < count; i++) {
      final list = ShoppingList(name: '${faker.lorem.word()} Shopping List ${i + 1}');
      final id = await listRepo.addList(list);
      final fetchedList = await listRepo.getListById(id);
      if (fetchedList != null) {
        lists.add(fetchedList);
      }
    }
    return lists;
  }

  static Future<void> _generateShoppingItems(
    ShoppingList list,
    int count,
    List<Brand> allBrands,
    List<GroceryStore> allStores,
    int priceEntriesPerItem,
  ) async {
    final itemRepo = getIt<IShoppingItemRepository>();
    final productVariantRepo = getIt<IProductVariantRepository>(); // Added

    for (int i = 0; i < count; i++) {
      final baseItemName = faker.commerce.productName(); // This is like a base product name

      // Create ProductVariant
      final productVariant = ProductVariant(
        name: "$baseItemName ${faker.commerce.productAdjective()} ${faker.commerce.productMaterial()}", // Example descriptive name
        baseProductName: baseItemName,
      );

      Brand? selectedBrandForVariant;
      if (allBrands.isNotEmpty && faker.datatype.boolean()) {
        selectedBrandForVariant = allBrands[_random.nextInt(allBrands.length)];
        productVariant.brand.target = selectedBrandForVariant;
      }
      // Save ProductVariant
      final productVariantId = await productVariantRepo.addProductVariant(productVariant);
      productVariant.id = productVariantId; // Ensure the object has the ID for linking

      final item = ShoppingItem(
        name: baseItemName, // ShoppingItem.name can remain the base name
        quantity: faker.datatype.number(max: 10, min: 1).toDouble(),
        unit: AppConstants.predefinedUnits[_random.nextInt(AppConstants.predefinedUnits.length)],
        category: faker.commerce.department(),
      );
      item.shoppingList.targetId = list.id;
      item.preferredVariant.target = productVariant; // Link to the created ProductVariant

      // Optionally, make ShoppingItem.brand consistent with ProductVariant's brand
      if (selectedBrandForVariant != null) {
        item.brand.target = selectedBrandForVariant;
      }

      if (allStores.isNotEmpty) {
        final numStoresForItem = faker.datatype.number(max: allStores.length, min: 1);
        final selectedStores = List<GroceryStore>.from(allStores)..shuffle(_random);
        for (int j = 0; j < numStoresForItem; j++) {
          if (j < selectedStores.length) { // Ensure we don't go out of bounds
            item.groceryStores.add(selectedStores[j]);
          }
        }
      }
      
      await itemRepo.addItem(item, list.id);

      // Pass the created ProductVariant object to _generatePriceEntries
      await _generatePriceEntries(productVariant, priceEntriesPerItem, allStores);
    }
  }

  static Future<void> _generatePriceEntries(
    ProductVariant productVariant, // Changed: Accept ProductVariant
    int count,
    List<GroceryStore> allStores,
    // List<Brand> allBrands, // Removed: Brand is on ProductVariant
  ) async {
    final priceRepo = getIt<IPriceEntryRepository>();

    for (int i = 0; i < count; i++) {
      if (allStores.isEmpty) continue;

      final store = allStores[_random.nextInt(allStores.length)];
      final priceValue = double.parse(faker.commerce.price(max: 50, min: 1, symbol: ''));
      final price = PriceEntry(
        price: priceValue,
        date: faker.date.between(DateTime(2023, 1, 1), DateTime(2025, 12, 31)),
        // canonicalItemName: canonicalItemName, // Removed
      );
      price.groceryStore.target = store;
      price.productVariant.target = productVariant; // Link to the passed ProductVariant

      // Brand is now on ProductVariant, so no need to set it directly on PriceEntry
      // if (allBrands.isNotEmpty && faker.datatype.boolean()) {
      //   price.brand.target = allBrands[_random.nextInt(allBrands.length)];
      // }
      await priceRepo.addPriceEntry(price);
    }
  }

  static Future<void> clearAppData() async {
    final objectBoxHelper = getIt<ObjectBoxHelper>();
    await objectBoxHelper.clearAllData();
    logInfo('All app data cleared.');
  }
}
