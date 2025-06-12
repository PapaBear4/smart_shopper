part of 'product_variant_cubit.dart';

abstract class ProductVariantState extends Equatable {
  const ProductVariantState();

  @override
  List<Object?> get props => [];
}

class ProductVariantInitial extends ProductVariantState {}

class ProductVariantLoading extends ProductVariantState {}

class ProductVariantSaving extends ProductVariantState {} // New state

class ProductVariantLoaded extends ProductVariantState {
  final List<ProductVariant> productVariants;

  const ProductVariantLoaded(this.productVariants);

  @override
  List<Object?> get props => [productVariants];
}

class ProductVariantSaveSuccess extends ProductVariantState { // New state
  final ProductVariant? variant; // Optional: pass the saved variant
  const ProductVariantSaveSuccess({this.variant});

  @override
  List<Object?> get props => [variant];
}

class ProductVariantError extends ProductVariantState {
  final String message;

  const ProductVariantError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductVariantSaveError extends ProductVariantState { // New state
  final String message;

  const ProductVariantSaveError(this.message);

  @override
  List<Object?> get props => [message];
}
