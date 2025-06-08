import 'package:faker_dart/faker_dart.dart'; // Changed import to faker_dart
import 'dart:math'; // Import dart:math for Random
import 'package:smart_shopper/models/models.dart';
import 'package:smart_shopper/objectbox_helper.dart';
import 'package:smart_shopper/repositories/brand_repository.dart';
import 'package:smart_shopper/repositories/price_entry_repository.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/repositories/shopping_list_repository.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
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

    for (int i = 0; i < count; i++) {
      final itemName = faker.commerce.productName();
      final item = ShoppingItem(
        name: itemName,
        quantity: faker.datatype.number(max: 10, min: 1).toDouble(),
        unit: AppConstants.predefinedUnits[_random.nextInt(AppConstants.predefinedUnits.length)], // Select from AppConstants
        category: faker.commerce.department(),
      );
      item.shoppingList.targetId = list.id;

      if (allBrands.isNotEmpty && faker.datatype.boolean()) {
        item.brand.target = allBrands[_random.nextInt(allBrands.length)]; // Corrected: Select from list using Random
      }

      if (allStores.isNotEmpty) {
        final numStoresForItem = faker.datatype.number(max: allStores.length, min: 1);
        final selectedStores = List<GroceryStore>.from(allStores)..shuffle(_random); // Pass Random instance to shuffle
        for (int j = 0; j < numStoresForItem; j++) {
          item.groceryStores.add(selectedStores[j]);
        }
      }
      
      await itemRepo.addItem(item, list.id);
      // Retrieve the added item to ensure we have its ID for price entries if needed,
      // or rely on the fact that addItem might populate the ID in the passed 'item' object if it's designed that way.
      // For simplicity, we'll assume item.id is populated or not strictly needed for price entry linking here,
      // as PriceEntry uses canonicalItemName.

      await _generatePriceEntries(itemName, priceEntriesPerItem, allStores, allBrands);
    }
  }

  static Future<void> _generatePriceEntries(
    String canonicalItemName,
    int count,
    List<GroceryStore> allStores,
    List<Brand> allBrands,
  ) async {
    final priceRepo = getIt<IPriceEntryRepository>();

    for (int i = 0; i < count; i++) {
      if (allStores.isEmpty) continue;

      final store = allStores[_random.nextInt(allStores.length)]; // Corrected: Select from list using Random
      final priceValue = double.parse(faker.commerce.price(max: 50, min: 1, symbol: ''));
      final price = PriceEntry(
        price: priceValue,
        date: faker.date.between(DateTime(2023, 1, 1), DateTime(2025, 12, 31)),
        canonicalItemName: canonicalItemName,
      );
      price.groceryStore.target = store;

      if (allBrands.isNotEmpty && faker.datatype.boolean()) {
        price.brand.target = allBrands[_random.nextInt(allBrands.length)]; // Corrected: Select from list using Random
      }
      await priceRepo.addPriceEntry(price);
    }
  }

  static Future<void> clearAppData() async {
    final objectBoxHelper = getIt<ObjectBoxHelper>();
    await objectBoxHelper.clearAllData();
    logInfo('All app data cleared.');
  }
}
