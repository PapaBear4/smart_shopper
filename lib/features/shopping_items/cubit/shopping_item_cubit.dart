import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart'; // Import item repository

part 'shopping_item_state.dart'; // Link state file

class ShoppingItemCubit extends Cubit<ShoppingItemState> {
  final IShoppingItemRepository _repository;
  final int listId; // ID of the shopping list we are managing items for
  StreamSubscription? _itemSubscription;
  ShoppingList? _parentList; // Cache the parent list details

  ShoppingItemCubit({
    required IShoppingItemRepository repository,
    required this.listId,
  }) : _repository = repository,
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
      _itemSubscription = _repository
          .getItemsStream(listId)
          .listen(
            (items) {
              // When new items arrive, emit loaded state with items and cached parent list
              if (_parentList != null) {
                // Ensure parent list is still available
                // Preserve existing showCompletedItems, groupByCategory, and groupByStore values if state is already ShoppingItemLoaded
                final bool showCompleted = state is ShoppingItemLoaded
                    ? (state as ShoppingItemLoaded).showCompletedItems
                    : false; // Default to false
                final bool groupingByCategory = state is ShoppingItemLoaded
                    ? (state as ShoppingItemLoaded).groupByCategory
                    : false; // Default to false
                final bool groupingByStore = state is ShoppingItemLoaded
                    ? (state as ShoppingItemLoaded).groupByStore
                    : false; // Default to false
                    
                emit(ShoppingItemLoaded(
                  items,
                  _parentList!,
                  showCompletedItems: showCompleted,
                  groupByCategory: groupingByCategory,
                  groupByStore: groupingByStore, // Preserve groupByStore state
                ));
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

  Future<void> addItem(ShoppingItem item) async {
    try {
      // The repository handles linking it to the listId
      await _repository.addItem(item, listId);
      // UI updates via stream subscription
    } catch (e) {
      emit(ShoppingItemError("Failed to add item: $e"));
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
        isCompleted: !item.isCompleted, // Flip the value
        // IMPORTANT: Keep relation links intact when updating
      )
      ..shoppingList.targetId =
          item.shoppingList.targetId; // Preserve ToOne link

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

  void toggleShowCompletedItems() {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      emit(currentState.copyWith(showCompletedItems: !currentState.showCompletedItems));
    }
  }

  void toggleGroupByCategory() {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      emit(currentState.copyWith(groupByCategory: !currentState.groupByCategory, groupByStore: false));
    }
  }

  void toggleGroupByStore() {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      emit(currentState.copyWith(groupByStore: !currentState.groupByStore, groupByCategory: false));
    }
  }

  Future<void> uncheckAllItems() async {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      List<ShoppingItem> itemsToUpdate = [];
      for (var item in currentState.items) {
        if (item.isCompleted) {
          // Create a copy with isCompleted set to false
          final updatedItem = ShoppingItem(
            id: item.id,
            name: item.name,
            category: item.category,
            quantity: item.quantity,
            unit: item.unit,
            isCompleted: false, // Uncheck the item
          )
            ..shoppingList.targetId = item.shoppingList.targetId
            ..brand.targetId = item.brand.targetId;
          updatedItem.groceryStores.addAll(item.groceryStores);
          itemsToUpdate.add(updatedItem);
        }
      }
      if (itemsToUpdate.isNotEmpty) {
        try {
          await _repository.updateItems(itemsToUpdate); 
          // UI will update via stream
        } catch (e) {
          emit(ShoppingItemError("Failed to uncheck all items: $e"));
        }
      }
    }
  }

  @override
  Future<void> close() {
    _itemSubscription?.cancel();
    return super.close();
  }
}
