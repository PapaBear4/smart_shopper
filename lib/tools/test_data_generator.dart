import 'dart:math';
import 'dart:math' as Math;

import '../models/models.dart';
import '../repositories/repositories.dart';

/// A utility class to generate test data for the Smart Shopper app.
/// This is intended for development and testing purposes only.
class TestDataGenerator {
  final IShoppingItemRepository _itemRepository;
  final IShoppingListRepository _listRepository;
  final IStoreRepository _storeRepository;
  
  final Random _random = Random();

  TestDataGenerator(
    this._itemRepository,
    this._listRepository,
    this._storeRepository,
  );

  /// Generate a complete set of test data including stores, lists, and items.
  Future<void> generateAllTestData() async {
    final stores = await generateGroceryStores();
    final lists = await generateShoppingLists();
    await generateShoppingItems(lists, stores);
  }

  /// Generate sample grocery stores
  Future<List<GroceryStore>> generateGroceryStores() async {
    final storeNames = [
      "Trader Joe's",
      "Whole Foods",
      "Safeway",
      "Costco",
      "Kroger",
      "Aldi",
      "Walmart",
      "Target",
      "Publix",
      "Meijer"
    ];
    
    final addresses = [
      "123 Market Street",
      "456 Organic Avenue",
      "789 Grocery Lane",
      "101 Bulk Boulevard",
      "202 Retail Road",
      "303 Shopping Street",
      "404 Food Avenue",
      "505 Produce Place",
      "606 Commerce Court",
      "707 Value Drive"
    ];
    
    final websites = [
      "www.traderjoes.com",
      "www.wholefoods.com",
      "www.safeway.com",
      "www.costco.com",
      "www.kroger.com",
      "www.aldi.com",
      "www.walmart.com",
      "www.target.com",
      "www.publix.com",
      "www.meijer.com"
    ];

    final stores = <GroceryStore>[];
    
    // Add stores while ensuring uniqueness
    final usedIndices = <int>{};
    
    // Create 5-8 stores
    final numStores = _random.nextInt(4) + 5;
    for (int i = 0; i < numStores; i++) {
      int index;
      do {
        index = _random.nextInt(storeNames.length);
      } while (usedIndices.contains(index));
      
      usedIndices.add(index);
      
      // Generate a random 10-digit phone number (all digits)
      final phoneDigits = List.generate(10, (idx) => _random.nextInt(10).toString()).join();
      
      final store = GroceryStore(
        name: storeNames[index],
        address: addresses[index],
        phoneNumber: phoneDigits,
        website: websites[index],
      );
      
      // Save to repository
      final storeId = await _storeRepository.addStore(store);
      store.id = storeId;
      stores.add(store);
    }

    return stores;
  }

  /// Generate sample shopping lists
  Future<List<ShoppingList>> generateShoppingLists() async {
    final listNames = [
      "Weekly Groceries",
      "Party Supplies",
      "Camping Trip",
      "Pantry Restock",
      "Healthy Meal Prep",
      "Holiday Dinner",
      "Emergency Supplies",
      "BBQ Items"
    ];
    
    final lists = <ShoppingList>[];
    final usedIndices = <int>{};
    
    // Create 3-5 lists
    final numLists = _random.nextInt(3) + 3;
    for (int i = 0; i < numLists; i++) {
      int index;
      do {
        index = _random.nextInt(listNames.length);
      } while (usedIndices.contains(index));
      
      usedIndices.add(index);
      
      final list = ShoppingList(
        name: listNames[index],
      );
      
      // Save to repository
      final listId = await _listRepository.addList(list);
      list.id = listId;
      lists.add(list);
    }

    return lists;
  }

  /// Generate sample shopping items and link them to lists and stores
  Future<void> generateShoppingItems(List<ShoppingList> lists, List<GroceryStore> stores) async {
    // Sample categories
    final categories = [
      "Produce", "Dairy", "Bakery", "Meat", "Frozen", 
      "Canned Goods", "Snacks", "Beverages", "Household"
    ];
    
    // Sample units with appropriate cases
    final units = ["piece(s)", "lb", "oz", "gallon", "quart", "pint", "pack"];
    
    // Sample items organized by category
    final itemsByCategory = {
      "Produce": ["Apples", "Bananas", "Spinach", "Carrots", "Tomatoes", "Potatoes", "Lettuce", "Onions", "Broccoli", "Avocados"],
      "Dairy": ["Milk", "Eggs", "Cheese", "Yogurt", "Butter", "Cream", "Sour Cream", "Cottage Cheese", "Ice Cream"],
      "Bakery": ["Bread", "Bagels", "Muffins", "Cake", "Cookies", "Tortillas", "Pita", "Croissants"],
      "Meat": ["Chicken", "Beef", "Pork", "Turkey", "Salmon", "Tuna", "Ground Beef", "Bacon", "Sausage"],
      "Frozen": ["Pizza", "Vegetables", "Ice Cream", "Waffles", "TV Dinners", "Chicken Nuggets", "French Fries"],
      "Canned Goods": ["Soup", "Beans", "Tuna", "Corn", "Tomato Sauce", "Vegetable Broth", "Cranberry Sauce"],
      "Snacks": ["Chips", "Popcorn", "Pretzels", "Nuts", "Crackers", "Granola Bars", "Trail Mix", "Dried Fruit"],
      "Beverages": ["Coffee", "Tea", "Soda", "Juice", "Water", "Sports Drinks", "Wine", "Beer", "Kombucha"],
      "Household": ["Paper Towels", "Toilet Paper", "Dish Soap", "Laundry Detergent", "Garbage Bags", "Cleaning Spray"]
    };
    
    // Create items for each list
    for (final list in lists) {
      // Select 2-4 random categories for this list
      final selectedCategoryIndices = <int>{};
      final numCategories = _random.nextInt(3) + 2;
      
      for (int i = 0; i < numCategories && i < categories.length; i++) {
        int catIndex;
        do {
          catIndex = _random.nextInt(categories.length);
        } while (selectedCategoryIndices.contains(catIndex));
        selectedCategoryIndices.add(catIndex);
      }
      
      // For each selected category, add 2-5 items
      for (final catIndex in selectedCategoryIndices) {
        final category = categories[catIndex];
        final items = itemsByCategory[category] ?? [];
        
        // Skip if no items available for this category
        if (items.isEmpty) continue;
        
        // Create a set to track used item indices within this category
        final usedItemIndices = <int>{};
        final itemCount = _random.nextInt(4) + 2; // 2-5 items per category
        
        for (int i = 0; i < itemCount && i < items.length; i++) {
          // Get a unique item from this category
          int itemIndex;
          do {
            itemIndex = _random.nextInt(items.length);
          } while (usedItemIndices.contains(itemIndex));
          usedItemIndices.add(itemIndex);
          
          final name = items[itemIndex];
          
          // Create appropriate units and quantities based on the category
          String unit;
          double quantity;
          
          if (category == "Produce") {
            unit = _random.nextBool() ? "lb" : "piece(s)";
            quantity = _random.nextBool() ? _random.nextInt(3) + 1.0 : (_random.nextInt(4) + 1) * 0.5;
          } else if (category == "Dairy") {
            unit = _random.nextBool() ? "gallon" : "piece(s)";
            quantity = _random.nextBool() ? 1.0 : 2.0;
          } else if (category == "Bakery") {
            unit = "piece(s)";
            quantity = (_random.nextInt(2) + 1) * 1.0;
          } else if (category == "Meat") {
            unit = "lb";
            quantity = (_random.nextInt(4) + 1) * 0.5;
          } else {
            unit = units[_random.nextInt(units.length)];
            quantity = (_random.nextInt(5) + 1) * (_random.nextBool() ? 0.5 : 1.0);
          }
          
          // Create the shopping item
          final item = ShoppingItem(
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            isCompleted: _random.nextBool() && _random.nextBool(), // 25% chance of being completed
          );
          
          // Link to a random number of stores (0-3)
          if (stores.isNotEmpty) {
            final storeCount = _random.nextInt(Math.min(3, stores.length) + 1);
            final selectedStoreIndices = <int>{};
            
            for (int j = 0; j < storeCount; j++) {
              int storeIndex;
              do {
                storeIndex = _random.nextInt(stores.length);
              } while (selectedStoreIndices.contains(storeIndex));
              
              selectedStoreIndices.add(storeIndex);
              item.groceryStores.add(stores[storeIndex]);
            }
          }
          
          // Add the item to the database, connected to this list
          await _itemRepository.addItem(item, list.id);
        }
      }
    }
  }

  /// Clear all existing data from the database
  Future<void> clearAllData() async {
    // Get all shopping lists and delete them
    final lists = await _listRepository.getAllLists();
    for (final list in lists) {
      await _listRepository.deleteList(list.id);
    }
    
    // Get all stores and delete them
    final stores = await _storeRepository.getAllStores();
    for (final store in stores) {
      await _storeRepository.deleteStore(store.id);
    }
  }
}