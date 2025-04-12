import 'package:get_it/get_it.dart';
import 'package:smart_shopper/features/stores/cubit/store_cubit.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'objectbox.dart'; // Your ObjectBox helper class
import 'repositories/shopping_list_repository.dart'; // Import repository
import 'features/shopping_lists/cubit/shopping_list_cubit.dart'; // Import cubit

// Create a global instance of GetIt
final getIt = GetIt.instance;

// This function will configure our dependencies
void setupLocator(ObjectBox objectboxInstance) {
  // Register the ObjectBox instance we already created in main() as a Singleton
  if (!kReleaseMode) {
    log('GetIt: Registering ObjectBox instance', name: 'service_locator');
  }
  getIt.registerSingleton<ObjectBox>(objectboxInstance);
  
  // Force initialization of repositories immediately instead of waiting for lazy loading
  // This ensures they're ready when the app starts
  if (!kReleaseMode) {
    log('GetIt: Initializing ShoppingListRepository', name: 'service_locator');
  }
  
  // --- Register Repositories ---
  // Use singleton instead of lazySingleton to create immediately
  getIt.registerSingleton<IShoppingListRepository>(
    ShoppingListRepository(objectboxInstance),
    dispose: (repo) {
      if (!kReleaseMode) {
        log('GetIt: Disposing ShoppingListRepository', name: 'service_locator');
      }
      // Add any cleanup if needed
    },
  );
  
  if (!kReleaseMode) {
    log('GetIt: Initializing other repositories', name: 'service_locator');
  }
  
  getIt.registerSingleton<IShoppingItemRepository>(
    ShoppingItemRepository(objectboxInstance),
  );
  
  getIt.registerSingleton<IStoreRepository>(
    StoreRepository(objectboxInstance),
  );
  
  // --- Register Cubits/Blocs ---
  // Keep using factory for cubits since they should be recreated when needed
  if (!kReleaseMode) {
    log('GetIt: Registering ShoppingListCubit factory', name: 'service_locator');
  }
  
  getIt.registerFactory<ShoppingListCubit>(
    () => ShoppingListCubit(repository: getIt<IShoppingListRepository>()),
  );
  
  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(repository: getIt<IStoreRepository>()),
  );
  
  if (!kReleaseMode) {
    // Log repository state for debugging
    final repo = getIt<IShoppingListRepository>();
    if (repo is ShoppingListRepository) {
      log('GetIt: ShoppingListRepository initialized with box count: ${(repo as ShoppingListRepository).getCount()}', 
          name: 'service_locator');
    }
  }
}