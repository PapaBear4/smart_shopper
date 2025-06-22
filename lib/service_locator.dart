import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_shopper/data/repositories/box_barrel.dart';
import 'package:smart_shopper/domain/repositories/repository_barrel.dart';
import 'package:smart_shopper/features/brands/cubit/brand_cubit.dart';
import 'package:smart_shopper/objectbox_helper.dart';
import 'package:smart_shopper/services/llm_service.dart';
import 'package:smart_shopper/tools/logger.dart';

final getIt = GetIt.instance;

void setupLocator(ObjectBoxHelper objectboxHelperInstance) {
  if (!kReleaseMode) {
    logInfo('GetIt: Registering ObjectBoxHelper instance');
  }

  getIt.registerSingleton<ObjectBoxHelper>(objectboxHelperInstance);

  if (!kReleaseMode) {
    logInfo('GetIt: Initializing Repositories');
  }

  final store = objectboxHelperInstance.store;

  getIt.registerSingleton<BrandRepository>(BrandBox(store));
  getIt.registerSingleton<SubBrandRepository>(SubBrandBox(store));
  getIt.registerSingleton<ProductLineRepository>(ProductLineBox(store));
  getIt.registerSingleton<GroceryStoreRepository>(GroceryStoreBox(store));
  getIt.registerSingleton<PriceEntryRepository>(PriceEntryBox(store));
  getIt.registerSingleton<ProductVariantRepository>(ProductVariantBox(store));
  getIt.registerSingleton<ShoppingListRepository>(ShoppingListBox(store));
  getIt.registerSingleton<ShoppingItemRepository>(ShoppingItemBox(store));

  if (!kReleaseMode) {
    logInfo('GetIt: Registering Cubit factories');
  }

  getIt.registerFactory<BrandCubit>(
    () => BrandCubit(
      brandRepository: getIt<BrandRepository>(),
      subBrandRepository: getIt<SubBrandRepository>(),
      productLineRepository: getIt<ProductLineRepository>(),
    ),
  );
  // TODO: The following cubits need to be migrated to the new architecture
  // getIt.registerFactory<ShoppingListCubit>(
  //   () => ShoppingListCubit(repository: getIt<IShoppingListRepository>()),
  // );
  // getIt.registerFactory<ProductVariantCubit>(
  //   () => ProductVariantCubit(
  //     repository: getIt<IProductVariantRepository>(),
  //   ),
  // );
  // getIt.registerFactory<StoreCubit>(
  //   () => StoreCubit(getIt<IStoreRepository>()),
  // );
  // getIt.registerFactory<PriceEntryCubit>(
  //   () => PriceEntryCubit(getIt<IPriceEntryRepository>()),
  // );

  getIt.registerSingleton<LlmService>(LlmService());

  getIt.registerSingleton<ImageProcessingService>(ImageProcessingService());
}
