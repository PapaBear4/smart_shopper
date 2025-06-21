import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_shopper/data/repositories/brand_box.dart';
import 'package:smart_shopper/data/repositories/product_line_box.dart';
import 'package:smart_shopper/data/repositories/sub_brand_box.dart';
import 'package:smart_shopper/domain/repositories/brand_repository.dart';
import 'package:smart_shopper/domain/repositories/product_line_repository.dart';
import 'package:smart_shopper/domain/repositories/sub_brand_repository.dart';
import 'package:smart_shopper/features/brands/cubit/brand_cubit.dart';
import 'package:smart_shopper/features/price_entries/cubit/price_entry_cubit.dart';
import 'package:smart_shopper/features/product_variants/cubit/product_variant_cubit.dart';
import 'package:smart_shopper/features/scan_list/services/image_processing_service.dart';
import 'package:smart_shopper/features/shopping_lists/cubit/shopping_list_cubit.dart';
import 'package:smart_shopper/features/stores/cubit/store_cubit.dart';
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

  getIt.registerSingleton<BrandRepository>(
    BrandBox(getIt<ObjectBoxHelper>()),
  );

  getIt.registerSingleton<SubBrandRepository>(
    SubBrandBox(getIt<ObjectBoxHelper>()),
  );

  getIt.registerSingleton<ProductLineRepository>(
    ProductLineBox(getIt<ObjectBoxHelper>()),
  );
  // TODO: The following repositories need to be migrated to the new architecture
  // getIt.registerSingleton<IShoppingListRepository>(
  //   ShoppingListRepository(getIt<ObjectBoxHelper>()),
  // );
  // getIt.registerSingleton<IShoppingItemRepository>(
  //   ShoppingItemRepository(getIt<ObjectBoxHelper>()),
  // );
  // getIt.registerSingleton<IProductVariantRepository>(
  //   ProductVariantRepository(getIt<ObjectBoxHelper>()),
  // );
  // getIt.registerSingleton<IStoreRepository>(
  //   StoreRepository(getIt<ObjectBoxHelper>()),
  // );
  // getIt.registerSingleton<IPriceEntryRepository>(
  //   PriceEntryRepository(getIt<ObjectBoxHelper>()),
  // );

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
