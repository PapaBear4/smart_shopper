// lib/features/shopping_lists/cubit/shopping_list_cubit.dart
import 'dart:async'; // For StreamSubscription
import 'dart:developer';
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
        log("Cubit Listener: Received ${lists.length} lists."); // <-- ADD THIS
        emit(ShoppingListLoaded(lists)); // Emit loaded state with data
      },
      onError: (error, stackTrace) {
        // Add stackTrace parameter
        log(
          "Cubit Listener: ERROR loading lists.", // More descriptive message
          error: error, // Pass error object
          stackTrace: stackTrace, // Pass stack trace object
        );
        emit(ShoppingListError("Failed to load lists: $error"));
      },
    );
  }

  Future<void> addList(String name) async {
    log("Cubit: addList called with name: $name"); // <-- ADD THIS
    if (name.trim().isEmpty) {
      log("Cubit: addList - Name is empty, returning."); // <-- ADD THIS
      return;
    } // Basic validation

    try {
      final newList = ShoppingList(name: name.trim());
      log("Cubit: Calling repository.addList..."); // <-- ADD THIS
      await _repository.addList(newList);
      log("Cubit: repository.addList finished."); // <-- ADD THIS
      // No need to emit here, the stream subscription will trigger an update
    } catch (e, s) {
      log(
        "Cubit: ERROR adding list.", // More descriptive message
        error: e, // Pass error object
        stackTrace: s, // Pass stack trace object
      );
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
