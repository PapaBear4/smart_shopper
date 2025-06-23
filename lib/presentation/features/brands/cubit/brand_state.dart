part of 'brand_cubit.dart';

enum BrandStatus { initial, loading, success, failure }

class BrandState extends Equatable {
  const BrandState({
    this.status = BrandStatus.initial,
    this.brands = const <Brand>[],
    this.subBrands = const <SubBrand>[],
    this.productLines = const <ProductLine>[],
    this.selectedBrand,
    this.selectedSubBrand,
    this.errorMessage,
  });

  final BrandStatus status;
  final List<Brand> brands;
  final List<SubBrand> subBrands;
  final List<ProductLine> productLines;
  final Brand? selectedBrand;
  final SubBrand? selectedSubBrand;
  final String? errorMessage;

  BrandState copyWith({
    BrandStatus? status,
    List<Brand>? brands,
    List<SubBrand>? subBrands,
    List<ProductLine>? productLines,
    Brand? selectedBrand,
    bool clearSelectedBrand = false,
    SubBrand? selectedSubBrand,
    bool clearSelectedSubBrand = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return BrandState(
      status: status ?? this.status,
      brands: brands ?? this.brands,
      subBrands: subBrands ?? this.subBrands,
      productLines: productLines ?? this.productLines,
      selectedBrand: clearSelectedBrand ? null : selectedBrand ?? this.selectedBrand,
      selectedSubBrand: clearSelectedSubBrand ? null : selectedSubBrand ?? this.selectedSubBrand,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        brands,
        subBrands,
        productLines,
        selectedBrand,
        selectedSubBrand,
        errorMessage,
      ];
}
