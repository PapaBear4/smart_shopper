import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../../../repositories/product_variant_repository.dart';

part 'product_variant_state.dart';

class ProductVariantCubit extends Cubit<ProductVariantState> {
  final IProductVariantRepository _repository;

  ProductVariantCubit({required IProductVariantRepository repository})
      : _repository = repository,
        super(ProductVariantInitial());

  Future<void> loadProductVariants() async {
    try {
      emit(ProductVariantLoading());
      // Use the stream from the repository for real-time updates
      // For an initial load or if not using streams directly in UI:
      final variants = await _repository.getAllProductVariants();
      emit(ProductVariantLoaded(variants));
    } catch (e) {
      emit(ProductVariantError('Failed to load product variants:${e.toString()}'));
    }
  }

  Future<void> addProductVariant(ProductVariant variant) async {
    try {
      emit(ProductVariantSaving()); // Emit saving state
      await _repository.addProductVariant(variant);
      emit(ProductVariantSaveSuccess(variant: variant)); // Emit success state
      // No need to call loadProductVariants() here if the list screen will refresh
      // or if we update the state in a more granular way.
      // For now, let list screen handle refresh on pop if needed or listen to this success state.
    } catch (e) {
      emit(ProductVariantSaveError('Failed to add product variant: ${e.toString()}'));
      // Optionally, re-emit a loaded state if you want the UI to go back to showing the list
      // after an error, or let the form handle the error display.
    }
  }

  Future<void> updateProductVariant(ProductVariant variant) async {
    try {
      emit(ProductVariantSaving()); // Emit saving state
      await _repository.updateProductVariant(variant);
      emit(ProductVariantSaveSuccess(variant: variant)); // Emit success state
      // Similar to add, no explicit reload here, let UI react to success or refresh.
    } catch (e) {
      emit(ProductVariantSaveError('Failed to update product variant: ${e.toString()}'));
    }
  }

  Future<void> deleteProductVariant(int id) async {
    try {
      final success = await _repository.deleteProductVariant(id);
      if (success) {
        loadProductVariants(); // Reload to reflect changes
      } else {
        emit(ProductVariantError('Failed to delete product variant: ID ${id} not found or failed to remove.'));
        loadProductVariants(); 
      }
    } catch (e) {
      emit(ProductVariantError('Failed to delete product variant: ${e.toString()}'));
    }
  }

  Future<void> searchProductVariants(String searchTerm, {int? brandId}) async {
    try {
      emit(ProductVariantLoading());
      final variants = await _repository.searchVariants(searchTerm, brandId: brandId);
      emit(ProductVariantLoaded(variants));
    } catch (e) {
      emit(ProductVariantError('Failed to search product variants: ${e.toString()}'));
    }
  }
}
