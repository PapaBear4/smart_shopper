import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../../../repositories/price_entry_repository.dart';

part 'price_entry_state.dart';

class PriceEntryCubit extends Cubit<PriceEntryState> {
  final IPriceEntryRepository _repository;
  StreamSubscription? _priceEntrySubscription;

  // Optional: Add filters if you need to load price entries for specific items/stores/brands
  // final String? canonicalItemNameFilter;
  // final int? storeIdFilter;
  // final int? brandIdFilter;

  PriceEntryCubit({
    required IPriceEntryRepository repository,
    // this.canonicalItemNameFilter,
    // this.storeIdFilter,
    // this.brandIdFilter,
  }) : _repository = repository,
       super(PriceEntryInitial()) {
    _loadPriceEntries();
  }

  void _loadPriceEntries() {
    emit(PriceEntryLoading());
    _priceEntrySubscription?.cancel();
    // TODO: Modify getPriceEntriesStream in repository to accept filters if needed
    _priceEntrySubscription = _repository.getPriceEntriesStream().listen(
      (priceEntries) => emit(PriceEntryLoaded(priceEntries)),
      onError: (error) => emit(PriceEntryError("Failed to load price entries: $error")),
    );
  }

  Future<void> addPriceEntry(PriceEntry priceEntry) async {
    try {
      await _repository.addPriceEntry(priceEntry);
      // UI updates via stream
    } catch (e) {
      emit(PriceEntryError("Failed to add price entry: $e"));
    }
  }

  Future<void> updatePriceEntry(PriceEntry priceEntry) async {
    try {
      await _repository.updatePriceEntry(priceEntry);
      // UI updates via stream
    } catch (e) {
      emit(PriceEntryError("Failed to update price entry: $e"));
    }
  }

  Future<void> deletePriceEntry(int priceEntryId) async {
    try {
      await _repository.deletePriceEntry(priceEntryId);
      // UI updates via stream
    } catch (e) {
      emit(PriceEntryError("Failed to delete price entry: $e")); 
    }
  }

  @override
  Future<void> close() {
    _priceEntrySubscription?.cancel();
    return super.close();
  }
}
