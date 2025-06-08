import 'package:smart_shopper/models/models.dart';
import 'package:smart_shopper/objectbox_helper.dart';
import 'package:smart_shopper/repositories/brand_repository.dart';
import 'package:smart_shopper/repositories/price_entry_repository.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/repositories/shopping_list_repository.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
import 'package:smart_shopper/service_locator.dart';

class DebugUtilities {
  static Future<void> generateTestData() async {
    final storeRepo = getIt<IStoreRepository>();
    final brandRepo = getIt<IBrandRepository>();
    final listRepo = getIt<IShoppingListRepository>();
    final itemRepo = getIt<IShoppingItemRepository>();
    final priceRepo = getIt<IPriceEntryRepository>();

    // 0. Clear existing data to avoid duplicates if run multiple times
    await clearAppData();

    // 1. Create Grocery Stores
    final store1 = GroceryStore(name: 'MegaMart', address: '123 Main St');
    final store2 = GroceryStore(name: 'Local Grocer', address: '456 Oak Ave');
    final store1Id = await storeRepo.addStore(store1);
    final store2Id = await storeRepo.addStore(store2);
    final fetchedStore1 = await storeRepo.getStoreById(store1Id);
    final fetchedStore2 = await storeRepo.getStoreById(store2Id);

    // 2. Create Brands
    final brandA = Brand(name: 'Fresh Farms');
    final brandB = Brand(name: 'BestValue');
    final brandC = Brand(name: 'Organix');
    final brandAId = await brandRepo.addBrand(brandA);
    final brandBId = await brandRepo.addBrand(brandB);
    final brandCId = await brandRepo.addBrand(brandC);
    final fetchedBrandA = await brandRepo.getBrandById(brandAId);
    final fetchedBrandB = await brandRepo.getBrandById(brandBId);
    final fetchedBrandC = await brandRepo.getBrandById(brandCId);

    // 3. Create Shopping Lists
    final list1 = ShoppingList(name: 'Weekly Groceries');
    final list2 = ShoppingList(name: 'Party Supplies');
    final list1Id = await listRepo.addList(list1);
    final list2Id = await listRepo.addList(list2);

    // 4. Create Shopping Items
    // List 1 Items
    final item1L1 = ShoppingItem(name: 'Milk', quantity: 1, unit: 'gallon', category: 'Dairy', id: list1Id);
    if (fetchedBrandA != null) item1L1.brand.target = fetchedBrandA;
    if (fetchedStore1 != null) item1L1.groceryStores.add(fetchedStore1);
    await itemRepo.addItem(item1L1,list1Id);

    final item2L1 = ShoppingItem(name: 'Bread', quantity: 1, unit: 'loaf', category: 'Bakery', id: list1Id);
    if (fetchedBrandB != null) item2L1.brand.target = fetchedBrandB;
    if (fetchedStore1 != null) item2L1.groceryStores.add(fetchedStore1);
    await itemRepo.addItem(item2L1,list1Id);
    
    final item3L1 = ShoppingItem(name: 'Organic Apples', quantity: 5, unit: 'pieces', category: 'Produce', id: list1Id);
    if (fetchedBrandC != null) item3L1.brand.target = fetchedBrandC;
    if (fetchedStore2 != null) item3L1.groceryStores.add(fetchedStore2);
    await itemRepo.addItem(item3L1, list1Id);

    // List 2 Items
    final item1L2 = ShoppingItem(name: 'Chips', quantity: 2, unit: 'bags', category: 'Snacks', id: list2Id);
    if (fetchedBrandB != null) item1L2.brand.target = fetchedBrandB;
    if (fetchedStore1 != null) item1L2.groceryStores.add(fetchedStore1);
    await itemRepo.addItem(item1L2, list2Id);

    final item2L2 = ShoppingItem(name: 'Soda', quantity: 1, unit: '2-liter', category: 'Drinks', id: list2Id);
    // No brand for this one
    if (fetchedStore2 != null) item2L2.groceryStores.add(fetchedStore2);
    await itemRepo.addItem(item2L2, list2Id);

    // 5. Create Price Entries
    if (fetchedStore1 != null && fetchedBrandA != null) {
      final price1 = PriceEntry(price: 3.50, date: DateTime.now().subtract(const Duration(days: 7)), canonicalItemName: 'Milk');
      price1.groceryStore.target = fetchedStore1;
      price1.brand.target = fetchedBrandA;
      await priceRepo.addPriceEntry(price1);
    }
    if (fetchedStore1 != null && fetchedBrandB != null) {
      final price2 = PriceEntry(price: 2.20, date: DateTime.now().subtract(const Duration(days: 5)), canonicalItemName: 'Bread');
      price2.groceryStore.target = fetchedStore1;
      price2.brand.target = fetchedBrandB;
      await priceRepo.addPriceEntry(price2);
    }
    if (fetchedStore2 != null && fetchedBrandC != null) {
      final price3 = PriceEntry(price: 1.50, date: DateTime.now(), canonicalItemName: 'Organic Apples'); // Price per piece
      price3.groceryStore.target = fetchedStore2;
      price3.brand.target = fetchedBrandC;
      await priceRepo.addPriceEntry(price3);
    }
     if (fetchedStore1 != null && fetchedBrandB != null) {
      final price4 = PriceEntry(price: 4.00, date: DateTime.now().subtract(const Duration(days: 2)), canonicalItemName: 'Chips');
      price4.groceryStore.target = fetchedStore1;
      price4.brand.target = fetchedBrandB;
      await priceRepo.addPriceEntry(price4);
    }

    print('Test data generated.');
  }

  static Future<void> clearAppData() async {
    final objectBoxHelper = getIt<ObjectBoxHelper>();
    await objectBoxHelper.clearAllData();
    print('All app data cleared.');
  }
}
