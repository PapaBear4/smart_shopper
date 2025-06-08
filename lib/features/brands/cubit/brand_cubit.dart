import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../../../repositories/brand_repository.dart';

part 'brand_state.dart';

class BrandCubit extends Cubit<BrandState> {
  final IBrandRepository _repository;
  StreamSubscription? _brandSubscription;

  BrandCubit({required IBrandRepository repository}) 
      : _repository = repository,
        super(BrandInitial()) {
    _loadBrands();
  }

  void _loadBrands() {
    emit(BrandLoading());
    _brandSubscription?.cancel();
    _brandSubscription = _repository.getBrandsStream().listen(
      (brands) => emit(BrandLoaded(brands)),
      onError: (error) => emit(BrandError("Failed to load brands: $error")),
    );
  }

  Future<void> addBrand(Brand brand) async {
    try {
      await _repository.addBrand(brand);
      // UI updates via stream
    } catch (e) {
      emit(BrandError("Failed to add brand: $e"));
    }
  }

  Future<void> updateBrand(Brand brand) async {
    try {
      await _repository.updateBrand(brand);
      // UI updates via stream
    } catch (e) {
      emit(BrandError("Failed to update brand: $e"));
    }
  }

  Future<void> deleteBrand(int brandId) async {
    try {
      await _repository.deleteBrand(brandId);
      // UI updates via stream
    } catch (e) {
      emit(BrandError("Failed to delete brand: $e"));
    }
  }

  @override
  Future<void> close() {
    _brandSubscription?.cancel();
    return super.close();
  }
}
