// lib/features/shopping_lists/cubit/shopping_list_cubit.dart
import 'dart:async'; // For StreamSubscription
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart'; // Barrel file
import '../../../repositories/shopping_list_repository.dart'; // Repository

part 'shopping_list_state.dart'; // Link state file

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final IShoppingListRepository _repository;
  StreamSubscription? _listSubscription; // To listen to repository stream

  ShoppingListCubit({required IShoppingListRepository repository})
    : _repository = repository,
      super(ShoppingListInitial()) {
    _subscribeToLists(); // Start listening immediately
  }

  // Subscribe to the stream from the repository
  void _subscribeToLists() {
    emit(ShoppingListLoading()); // Indicate loading initially
    _listSubscription?.cancel(); // Cancel previous subscription if any
    _listSubscription = _repository.getAllListsStream().listen(
      (lists) {
        emit(ShoppingListLoaded(lists)); // Emit loaded state with data
      },
      onError: (error, stackTrace) {
        // Add stackTrace parameter
        emit(ShoppingListError("Failed to load lists: $error"));
      },
    );
  }

  Future<void> addList(String name) async {
    if (name.trim().isEmpty) {
      return;
    } // Basic validation

    try {
      final newList = ShoppingList(name: name.trim());
      await _repository.addList(newList);
      // No need to emit here, the stream subscription will trigger an update
    } catch (e) {
      emit(ShoppingListError("Failed to add list: $e"));
      // Re-emit previous loaded state if possible, or reload
      _subscribeToLists(); // Attempt to reload lists on error
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await _repository.deleteList(id);
      // Stream subscription handles the UI update
    } catch (e) {
      emit(ShoppingListError("Failed to delete list: $e"));
      _subscribeToLists(); // Attempt to reload lists on error
    }
  }

  Future<void> renameList(int id, String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      // Create an updated object with the same ID
      final updatedList = ShoppingList(id: id, name: newName.trim());
      await _repository.updateList(updatedList);
      // Stream handles UI update
    } catch (e) {
      emit(ShoppingListError("Failed to rename list: $e"));
      _subscribeToLists(); // Attempt to reload lists on error
    }
  }

  // Remember to cancel the subscription when the Cubit is closed
  @override
  Future<void> close() {
    _listSubscription?.cancel();
    return super.close();
  }
}
