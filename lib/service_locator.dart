import 'package:get_it/get_it.dart';
import 'package:smart_shopper/features/stores/cubit/store_cubit.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'objectbox.dart'; // Your ObjectBox helper class
import 'repositories/shopping_list_repository.dart'; // Import repository
import 'features/shopping_lists/cubit/shopping_list_cubit.dart'; // Import cubit

/// GetIt is a service locator for dependency injection (DI)
/// It allows you to register classes/objects and retrieve them from anywhere in your app
/// This avoids passing dependencies through constructors across many widget layers
final getIt = GetIt.instance;

/// Sets up all dependencies for the application
/// This function configures the service locator with all necessary repositories and cubits
/// @param objectboxInstance - The initialized ObjectBox database instance from main.dart
void setupLocator(ObjectBox objectboxInstance) {
  // Register the ObjectBox instance we already created in main() as a Singleton
  // A Singleton means there will only be ONE instance throughout the app's lifetime
  if (!kReleaseMode) {
    log('GetIt: Registering ObjectBox instance', name: 'service_locator');
  }
  getIt.registerSingleton<ObjectBox>(objectboxInstance);

  // --- Register Repositories ---
  // Repositories are registered as Singletons because we want to reuse the same instance
  // throughout the app to maintain data consistency
  // registerSingleton creates the instance immediately (eager initialization)
  // whereas lazySingleton would defer creation until first use
  // This ensures they're ready when the app starts
  if (!kReleaseMode) {
    log('GetIt: Initializing Repositories', name: 'service_locator');
  }
  getIt.registerSingleton<IShoppingListRepository>(
    ShoppingListRepository(objectboxInstance),
    dispose: (repo) {
      // This dispose function runs when the GetIt instance is reset or when
      // this singleton is unregistered, allowing cleanup operations
      if (!kReleaseMode) {
        log('GetIt: Disposing ShoppingListRepository', name: 'service_locator');
      }
      // Add any cleanup if needed
    },
  ); // end ShoppingListRepository

  // --- Initialize Shopping_Item Repository ---
  getIt.registerSingleton<IShoppingItemRepository>(
    ShoppingItemRepository(objectboxInstance),
  ); // end ShoppingItemRepository

  // --- Initialize Store Repository ---
  getIt.registerSingleton<IStoreRepository>(StoreRepository(objectboxInstance));
  // end StoreRepository

  // --- Register Cubits/Blocs ---
  // Cubits are registered as factories, meaning a NEW instance is created EACH time
  // they are requested with getIt<CubitType>()
  // This is appropriate for UI-related state management that may need to be recreated

  // The factory registration means:
  // - Each widget that needs a ShoppingListCubit gets a fresh instance
  // - But they all use the SAME repository underneath (singleton)
  // - This prevents state leaks between different parts of your UI
  if (!kReleaseMode) {
    log('GetIt: Registering Cubit factories', name: 'service_locator');
  }
  // Register the ShoppingListCubit with its repository
  getIt.registerFactory<ShoppingListCubit>(
    () => ShoppingListCubit(repository: getIt<IShoppingListRepository>()),
  ); // end ShoppingListCubit

  // Register the StoreCubit with its repository
  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(repository: getIt<IStoreRepository>()),
  ); // end StoreCubit
  
  // Note: ShoppingItemCubit is not registered here because:
  // 1. Shopping items are always associated with a specific shopping list
  // 2. The ShoppingItemCubit requires context about which list it's managing
  // 3. It's likely created dynamically when a specific list is accessed
  // 4. This approach prevents global access to items without their parent list context

  if (!kReleaseMode) {
    // Log repository state for debugging
    // This demonstrates how to retrieve a registered instance using getIt<Type>()
    final repo = getIt<IShoppingListRepository>();
    if (repo is ShoppingListRepository) {
      log(
        'GetIt: ShoppingListRepository initialized with box count: ${(repo).getCount()}',
        name: 'service_locator',
      );
    }
  }
}
