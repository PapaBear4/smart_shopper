// lib/features/shopping_lists/cubit/shopping_list_cubit.dart
import 'dart:async'; // For StreamSubscription
import 'package:bloc/bloc.dart';
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
        print(
          "Cubit Listener: Received ${lists.length} lists.",
        ); // <-- ADD THIS
        emit(ShoppingListLoaded(lists)); // Emit loaded state with data
      },
      onError: (error) {
        // TODO: Add proper error handling/logging
        print("Cubit Listener: ERROR - $error"); // <-- ADD THIS
        emit(ShoppingListError("Failed to load lists: $error"));
      },
    );
  }

  Future<void> addList(String name) async {
    print("Cubit: addList called with name: $name"); // <-- ADD THIS
    if (name.trim().isEmpty) {
      print("Cubit: addList - Name is empty, returning."); // <-- ADD THIS
      return;
    } // Basic validation

    try {
      final newList = ShoppingList(name: name.trim());
      print("Cubit: Calling repository.addList..."); // <-- ADD THIS
      await _repository.addList(newList);
      print("Cubit: repository.addList finished."); // <-- ADD THIS
      // No need to emit here, the stream subscription will trigger an update
    } catch (e) {
      // TODO: Improve error feedback
      print("Cubit: ERROR adding list: $e"); // <-- ADD THIS
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
