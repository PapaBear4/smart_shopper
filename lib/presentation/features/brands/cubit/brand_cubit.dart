import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_shopper/domain/entities/entities.dart';
import 'package:smart_shopper/domain/repositories/repositories.dart';

part 'brand_state.dart';

class BrandCubit extends Cubit<BrandState> {
  final BrandRepository _brandRepository;
  final SubBrandRepository _subBrandRepository;
  final ProductLineRepository _productLineRepository;

  BrandCubit({
    required BrandRepository brandRepository,
    required SubBrandRepository subBrandRepository,
    required ProductLineRepository productLineRepository,
  })  : _brandRepository = brandRepository,
        _subBrandRepository = subBrandRepository,
        _productLineRepository = productLineRepository,
        super(const BrandState());

  Future<void> loadBrands() async {
    emit(state.copyWith(status: BrandStatus.loading));
    try {
      final brands = await _brandRepository.getAll();
      emit(state.copyWith(status: BrandStatus.success, brands: brands));
    } catch (e) {
      emit(state.copyWith(status: BrandStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> selectBrand(Brand brand) async {
    emit(state.copyWith(status: BrandStatus.loading, selectedBrand: brand, clearSelectedSubBrand: true));
    try {
      final subBrands = await _subBrandRepository.getByBrand(brand.id);
      emit(state.copyWith(
        status: BrandStatus.success,
        subBrands: subBrands,
        productLines: [], // Clear product lines when brand changes
      ));
    } catch (e) {
      emit(state.copyWith(status: BrandStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> selectSubBrand(SubBrand subBrand) async {
    emit(state.copyWith(status: BrandStatus.loading, selectedSubBrand: subBrand));
    try {
      final productLines = await _productLineRepository.getBySubBrand(subBrand.id);
      emit(state.copyWith(status: BrandStatus.success, productLines: productLines));
    } catch (e) {
      emit(state.copyWith(status: BrandStatus.failure, errorMessage: e.toString()));
    }
  }

  // Methods for adding, updating, deleting brands, sub-brands, and product lines
  // will be added here.
}
