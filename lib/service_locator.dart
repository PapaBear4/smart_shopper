import 'package:get_it/get_it.dart';
import 'objectbox.dart'; // Your ObjectBox helper class

// Create a global instance of GetIt
final getIt = GetIt.instance;

// This function will configure our dependencies
void setupLocator(ObjectBox objectboxInstance) {
  // Register the ObjectBox instance we already created in main() as a Singleton.
  // This means GetIt will always return this same instance when requested.
  getIt.registerSingleton<ObjectBox>(objectboxInstance);

  // --- Placeholder for future registrations ---
  // Later, we'll register our Repositories and BLoCs here. For example:
  //
  // 1. Repositories (handle data operations, use ObjectBox)
  // getIt.registerLazySingleton<ShoppingRepository>(() => ShoppingRepository(getIt<ObjectBox>()));
  // getIt.registerLazySingleton<StoreRepository>(() => StoreRepository(getIt<ObjectBox>()));
  //
  // 2. BLoCs (handle logic, use Repositories)
  // getIt.registerFactory<ShoppingListBloc>(() => ShoppingListBloc(repository: getIt<ShoppingRepository>()));
  // getIt.registerFactory<StoreBloc>(() => StoreBloc(repository: getIt<StoreRepository>()));
  //
  // 'registerLazySingleton' creates the instance only when first requested.
  // 'registerFactory' creates a new instance every time it's requested.
}