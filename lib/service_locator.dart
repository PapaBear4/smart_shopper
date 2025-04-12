import 'package:get_it/get_it.dart';
import 'package:smart_shopper2/repositories/shopping_item_repository.dart';
import 'objectbox.dart'; // Your ObjectBox helper class
import 'repositories/shopping_list_repository.dart'; // Import repository
import 'features/shopping_lists/cubit/shopping_list_cubit.dart'; // Import cubit

// Create a global instance of GetIt
final getIt = GetIt.instance;

// This function will configure our dependencies
void setupLocator(ObjectBox objectboxInstance) {
  // Register the ObjectBox instance we already created in main() as a Singleton.
  // This means GetIt will always return this same instance when requested.
  getIt.registerSingleton<ObjectBox>(objectboxInstance);

  // --- Register Repositories ---
  // Use registerLazySingleton for repositories: create only when first needed
  getIt.registerLazySingleton<IShoppingListRepository>(
      () => ShoppingListRepository(getIt<ObjectBox>()), // Pass ObjectBox instance
  );
  getIt.registerLazySingleton<IShoppingItemRepository>(
    () => ShoppingItemRepository(getIt<ObjectBox>()),
  );
  // Register other repositories here (e.g., StoreRepository, ItemRepository)

  // --- Register Cubits/Blocs ---
  // Use registerFactory for Cubits/Blocs: create a new instance every time
  getIt.registerFactory<ShoppingListCubit>(
      () => ShoppingListCubit(repository: getIt<IShoppingListRepository>()), // Pass Repository instance
  );
  // Register other Cubits/Blocs here
  //
  // 'registerLazySingleton' creates the instance only when first requested.
  // 'registerFactory' creates a new instance every time it's requested.
}