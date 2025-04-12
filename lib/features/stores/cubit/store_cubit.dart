import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart'; // Models barrel file
import '../../../repositories/store_repository.dart'; // Import store repository

part 'store_state.dart'; // Link state file

class StoreCubit extends Cubit<StoreState> {
  final IStoreRepository _repository;
  StreamSubscription? _storeSubscription;

  StoreCubit({required IStoreRepository repository})
    : _repository = repository,
      super(StoreInitial()) {
    _subscribeToStores(); // Start listening to the store stream immediately
  }

  // Subscribe to the reactive stream from the repository
  void _subscribeToStores() {
    emit(StoreLoading());
    _storeSubscription?.cancel(); // Cancel any previous subscription
    _storeSubscription = _repository.getStoresStream().listen(
      // [cite: previous turn's repository code]
      (stores) {
        emit(StoreLoaded(stores)); // Emit loaded state with the latest list
      },
      onError: (error, s) {
        emit(StoreError("Failed to load stores: $error"));
      },
    );
  }

  Future<void> addStore({
    required String name,
    String? address,
    String? website,
    String? phone,
  }) async {
    if (name.trim().isEmpty) return; // Basic validation

    try {
      final newStore = GroceryStore(
        // [cite: uploaded:lib/models/grocery_store.dart]
        name: name.trim(),
        address: address?.trim(),
        website: website?.trim(),
        phoneNumber: phone?.trim(),
      );
      await _repository.addStore(
        newStore,
      ); // [cite: previous turn's repository code]
      // UI updates via the stream subscription
    } catch (e) {
      emit(StoreError("Failed to add store: $e"));
      // Optionally reload or revert
    }
  }

  Future<void> updateStore(GroceryStore store) async {
    // Ensure name isn't empty if updating
    if (store.name.trim().isEmpty) {
      emit(const StoreError("Store name cannot be empty."));
      return;
    }
    try {
      await _repository.updateStore(
        store,
      ); // [cite: previous turn's repository code]
      // UI updates via the stream subscription
    } catch (e) {
      emit(StoreError("Failed to update store: $e"));
    }
  }

  Future<void> deleteStore(int storeId) async {
    try {
      await _repository.deleteStore(
        storeId,
      ); // [cite: previous turn's repository code]
      // UI updates via the stream subscription
    } catch (e) {
      emit(StoreError("Failed to delete store: $e"));
    }
  }

  // Cancel subscription when Cubit is closed
  @override
  Future<void> close() {
    _storeSubscription?.cancel();
    return super.close();
  }
}
