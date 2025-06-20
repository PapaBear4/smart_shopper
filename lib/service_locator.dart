import 'package:get_it/get_it.dart';
import 'package:smart_shopper/features/brands/cubit/brand_cubit.dart';
import 'package:smart_shopper/features/price_entries/cubit/price_entry_cubit.dart';
import 'package:smart_shopper/features/stores/cubit/store_cubit.dart';
import 'package:flutter/foundation.dart';
import 'objectbox_helper.dart'; // Your ObjectBox helper class
import 'package:smart_shopper/repositories/repositories.dart';
import 'features/shopping_lists/cubit/shopping_list_cubit.dart'; // Import cubit
import 'package:smart_shopper/services/llm_service.dart'; // Import the LLM Service
import 'features/product_variants/cubit/product_variant_cubit.dart'; // Import ProductVariantCubit
import 'features/scan_list/services/image_processing_service.dart'; // Import ImageProcessingService
import 'package:smart_shopper/tools/logger.dart'; // Import the logger

/// GetIt is a service locator for dependency injection (DI)
/// It allows you to register classes/objects and retrieve them from anywhere in your app
/// This avoids passing dependencies through constructors across many widget layers
final getIt = GetIt.instance;

/// Sets up all dependencies for the application
/// This function configures the service locator with all necessary repositories and cubits
/// @param objectboxInstance - The initialized ObjectBox database instance from main.dart
void setupLocator(ObjectBoxHelper objectboxHelperInstance) {
  if (!kReleaseMode) {
    logInfo('GetIt: Registering ObjectBoxHelper instance');
  }
  // Register the ObjectBoxHelper as a singleton. This ensures there's only one instance
  // of the database helper throughout the application's lifecycle.
  getIt.registerSingleton<ObjectBoxHelper>(objectboxHelperInstance);

  if (!kReleaseMode) {
    logInfo('GetIt: Initializing Repositories');
  }

  // --- Register Repositories as Singletons ---
  // Repositories manage data operations and are typically singletons
  // to maintain state consistency and avoid resource duplication (like database connections).

  // Register the ShoppingListRepository
  getIt.registerSingleton<IShoppingListRepository>(
    ShoppingListRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the ShoppingItemRepository
  getIt.registerSingleton<IShoppingItemRepository>(
    ShoppingItemRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the ProductVariantRepository
  getIt.registerSingleton<IProductVariantRepository>(
    ProductVariantRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the StoreRepository
  getIt.registerSingleton<IStoreRepository>(
    StoreRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the PriceEntryRepository
  getIt.registerSingleton<IPriceEntryRepository>(
    PriceEntryRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the BrandRepository
  getIt.registerSingleton<IBrandRepository>(
    BrandRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the SubBrandRepository
  getIt.registerSingleton<ISubBrandRepository>(
    SubBrandRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the ProductLineRepository
  getIt.registerSingleton<IProductLineRepository>(
    ProductLineRepository(getIt<ObjectBoxHelper>()),
  );

  // Register the LLM service
  getIt.registerSingleton<LlmService>(LlmService());

  // Register the ImageProcessingService
  getIt.registerSingleton<ImageProcessingService>(ImageProcessingService());

  // --- Register Cubits/Blocs ---
  // Cubits are registered as factories, meaning a NEW instance is created EACH time
  // they are requested with getIt<CubitType>()
  // This is appropriate for UI-related state management that may need to be recreated

  // The factory registration means:
  // - Each widget that needs a ShoppingListCubit gets a fresh instance
  // - But they all use the SAME repository underneath (singleton)
  // - This prevents state leaks between different parts of your UI
  if (!kReleaseMode) {
    logInfo('GetIt: Registering Cubit factories');
  }
  // Register the ShoppingListCubit with its repository
  getIt.registerFactory<ShoppingListCubit>(
    () => ShoppingListCubit(repository: getIt<IShoppingListRepository>()),
  ); // end ShoppingListCubit

  // Register the StoreCubit with its repository
  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(repository: getIt<IStoreRepository>()),
  ); // end StoreCubit

  // Register BrandCubit
  getIt.registerFactory<BrandCubit>(
    () => BrandCubit(repository: getIt<IBrandRepository>()),
  );

  // Register PriceEntryCubit
  // If you add filters, you'll need to decide how they are provided.
  // For now, registering without filters:
  getIt.registerFactory<PriceEntryCubit>(
    () => PriceEntryCubit(repository: getIt<IPriceEntryRepository>()),
  );

  // Register ProductVariantCubit
  getIt.registerFactory<ProductVariantCubit>(
    () => ProductVariantCubit(repository: getIt<IProductVariantRepository>()),
  );

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
      logInfo(
        'GetIt: ShoppingListRepository initialized with box count: ${(repo).getCount()}',
      );
    }
  }
}
