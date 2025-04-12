import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart'; // Import item repository

part 'shopping_item_state.dart'; // Link state file

class ShoppingItemCubit extends Cubit<ShoppingItemState> {
  final IShoppingItemRepository _repository;
  final int listId; // ID of the shopping list we are managing items for
  StreamSubscription? _itemSubscription;
  ShoppingList? _parentList; // Cache the parent list details

  ShoppingItemCubit({required IShoppingItemRepository repository, required this.listId})
      : _repository = repository,
        super(ShoppingItemInitial()) {
    loadInitialData();
  }

  // Fetch parent list details and subscribe to item stream
  Future<void> loadInitialData() async {
    emit(ShoppingItemLoading());
    try {
      // Fetch the parent list details first
      _parentList = await _repository.getShoppingList(listId);
      if (_parentList == null) {
        emit(const ShoppingItemError("Parent shopping list not found."));
        return;
      }

      // Now subscribe to the items stream
      _itemSubscription?.cancel(); // Cancel previous subscription if any
      _itemSubscription = _repository.getItemsStream(listId).listen(
        (items) {
          // When new items arrive, emit loaded state with items and cached parent list
          if (_parentList != null) { // Ensure parent list is still available
             emit(ShoppingItemLoaded(items, _parentList!));
          } else {
             // This case should ideally not happen if initial load succeeded
             emit(const ShoppingItemError("Parent list data lost."));
          }
        },
        onError: (error) {
          emit(ShoppingItemError("Failed to load items: $error"));
        },
      );
    } catch (e) {
       emit(ShoppingItemError("Failed to initialize item view: $e"));
    }
  }

  Future<void> addItem(String name, String category, double quantity, String unit) async {
    if (name.trim().isEmpty) return; // Add more validation as needed

    try {
      final newItem = ShoppingItem(
        name: name.trim(),
        category: category.trim(), // Assuming category/unit are simple strings for now
        quantity: quantity,
        unit: unit.trim(),
        isCompleted: false,
      );
      // The repository handles linking it to the listId
      await _repository.addItem(newItem, listId);
      // UI updates via stream subscription
    } catch (e) {
       emit(ShoppingItemError("Failed to add item: $e"));
       // Optionally re-fetch or revert state if needed
    }
  }

   Future<void> updateItem(ShoppingItem item) async {
    try {
      await _repository.updateItem(item);
       // UI updates via stream subscription
    } catch (e) {
      emit(ShoppingItemError("Failed to update item: $e"));
    }
  }

  Future<void> toggleItemCompletion(ShoppingItem item) async {
     // Create a copy with the toggled state
    final updatedItem = ShoppingItem(
        id: item.id, // Keep the same ID!
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        isCompleted: !item.isCompleted // Flip the value
        // IMPORTANT: Keep relation links intact when updating
      )..shoppingList.targetId = item.shoppingList.targetId; // Preserve ToOne link

      // Copy ToMany links (if necessary, though often ObjectBox handles this if only scalar fields change)
      updatedItem.groceryStores.addAll(item.groceryStores);

    await updateItem(updatedItem); // Call the general update method
  }


  Future<void> deleteItem(int itemId) async {
    try {
      await _repository.deleteItem(itemId);
       // UI updates via stream subscription
    } catch (e) {
       emit(ShoppingItemError("Failed to delete item: $e"));
    }
  }

  @override
  Future<void> close() {
    _itemSubscription?.cancel();
    return super.close();
  }
}