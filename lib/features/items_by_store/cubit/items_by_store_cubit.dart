import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart';
import '../../../repositories/store_repository.dart';
import '../../../service_locator.dart'; // For getIt

part 'items_by_store_state.dart';

class ItemsByStoreCubit extends Cubit<ItemsByStoreState> {
  final IShoppingItemRepository _shoppingItemRepository;
  final IStoreRepository _storeRepository;
  StreamSubscription<List<ShoppingItem>>? _itemsSubscription;
  final int storeId;

  ItemsByStoreCubit({required this.storeId}) 
      : _shoppingItemRepository = getIt<IShoppingItemRepository>(),
        _storeRepository = getIt<IStoreRepository>(),
        super(ItemsByStoreInitial()) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    emit(ItemsByStoreLoading());
    try {
      final store = await _storeRepository.getStoreById(storeId);
      if (store == null) {
        emit(const ItemsByStoreError('Store not found.'));
        return;
      }

      _itemsSubscription?.cancel();
      _itemsSubscription = _shoppingItemRepository.getItemsForStoreStream(storeId).listen((items) {
        // Ensure we emit ItemsByStoreLoaded with the current showCompletedItems value
        final currentState = state;
        bool showCompleted = true; // Default if not already loaded
        bool groupByCat = true; // Default for groupByCategory
        bool groupByLst = false; // Default for groupByList
        if (currentState is ItemsByStoreLoaded) {
          showCompleted = currentState.showCompletedItems;
          groupByCat = currentState.groupByCategory;
          groupByLst = currentState.groupByList;
        }
        emit(ItemsByStoreLoaded(items, store, showCompletedItems: showCompleted, groupByCategory: groupByCat, groupByList: groupByLst));
      }, onError: (error) {
        emit(ItemsByStoreError('Failed to load items: ${error.toString()}'));
      });
    } catch (e) {
      emit(ItemsByStoreError('Failed to load items: ${e.toString()}'));
    }
  }

  Future<void> toggleItemCompletion(ShoppingItem item) async {
    final updatedItem = ShoppingItem(
      id: item.id,
      name: item.name,
      category: item.category,
      quantity: item.quantity,
      unit: item.unit,
      isCompleted: !item.isCompleted, // Toggle status
    );
    // Copy relations
    updatedItem.shoppingList.target = item.shoppingList.target;
    updatedItem.brand.target = item.brand.target;
    updatedItem.groceryStores.addAll(item.groceryStores);
    
    await _shoppingItemRepository.updateItem(updatedItem);
    // The stream will automatically update the UI
  }

  Future<void> deleteItem(ShoppingItem item) async {
    // No need to check state, repository handles if item exists or not
    await _shoppingItemRepository.deleteItem(item.id);
    // The stream will automatically update the UI by removing the item
    // If direct feedback or error handling specific to this screen is needed,
    // you might emit a new state or handle errors from the repository call.
  }

  Future<void> updateItemDetails(ShoppingItem itemToUpdate) async {
    if (state is ItemsByStoreLoaded) {
      final currentState = state as ItemsByStoreLoaded;
      try {
        await _shoppingItemRepository.updateItem(itemToUpdate); 
        final index = currentState.items.indexWhere((item) => item.id == itemToUpdate.id);
        if (index != -1) {
          final updatedItems = List<ShoppingItem>.from(currentState.items);
          updatedItems[index] = itemToUpdate;
          emit(currentState.copyWith(items: updatedItems));
        } else {
          await _loadItems(); // Corrected method name
        }
      } catch (e) {
        emit(ItemsByStoreError('Error updating item: \${e.toString()}'));
      }
    }
  }

  Future<void> addItem(ShoppingItem newItem) async {
    if (state is ItemsByStoreLoaded) {
      final currentState = state as ItemsByStoreLoaded;
      try {
        if (newItem.shoppingList.target == null || newItem.shoppingList.targetId == 0) {
          emit(const ItemsByStoreError('Cannot add item without a shopping list.')); // Added const
          return;
        }
        final newItemId = await _shoppingItemRepository.addItem(newItem, newItem.shoppingList.targetId);
        
        // Manually create a new ShoppingItem instance with the new ID
        final createdItem = ShoppingItem(
          id: newItemId,
          name: newItem.name,
          category: newItem.category,
          quantity: newItem.quantity,
          unit: newItem.unit,
          isCompleted: newItem.isCompleted,
          // Ensure relations are preserved if they were set on newItem
        );
        createdItem.shoppingList.target = newItem.shoppingList.target;
        createdItem.brand.target = newItem.brand.target;
        createdItem.groceryStores.addAll(newItem.groceryStores);
        createdItem.priceEntries.addAll(newItem.priceEntries);

        final updatedItems = List<ShoppingItem>.from(currentState.items)..add(createdItem);
        emit(currentState.copyWith(items: updatedItems));

      } catch (e) {
        emit(ItemsByStoreError('Error adding item: \${e.toString()}'));
      }
    }
  }

  Future<void> uncheckAllItems() async {
    if (state is ItemsByStoreLoaded) {
      final loadedState = state as ItemsByStoreLoaded;
      final List<ShoppingItem> updatedItems = [];
      bool changed = false;
      for (var item in loadedState.items) {
        if (item.isCompleted) {
          final updatedItem = ShoppingItem(
            id: item.id,
            name: item.name,
            category: item.category,
            quantity: item.quantity,
            unit: item.unit,
            isCompleted: false, // Uncheck
          );
          updatedItem.shoppingList.target = item.shoppingList.target;
          updatedItem.brand.target = item.brand.target;
          updatedItem.groceryStores.addAll(item.groceryStores);
          updatedItems.add(updatedItem);
          changed = true;
        } else {
          updatedItems.add(item); // Add unchanged item
        }
      }
      if (changed) {
        await _shoppingItemRepository.updateItems(updatedItems.where((i) => !i.isCompleted).toList()); // Only update those that were changed
        // The stream will update the state, or we can emit a new state here if direct feedback is needed
        // For now, relying on the stream from _loadItems to refresh.
        // emit(loadedState.copyWith(items:allItems)); // Potentially emit new state if stream doesn't cover it fast enough
      }
    }
  }

  void toggleShowCompletedItems() {
    if (state is ItemsByStoreLoaded) {
      final loadedState = state as ItemsByStoreLoaded;
      emit(loadedState.copyWith(showCompletedItems: !loadedState.showCompletedItems));
    }
  }

  void toggleGroupByCategory() {
    if (state is ItemsByStoreLoaded) {
      final loadedState = state as ItemsByStoreLoaded;
      emit(loadedState.copyWith(groupByCategory: !loadedState.groupByCategory, groupByList: !loadedState.groupByCategory ? false : loadedState.groupByList));
    }
  }

  void toggleGroupByList() {
    if (state is ItemsByStoreLoaded) {
      final loadedState = state as ItemsByStoreLoaded;
      emit(loadedState.copyWith(groupByList: !loadedState.groupByList, groupByCategory: !loadedState.groupByList ? false : loadedState.groupByCategory));
    }
  }

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    return super.close();
  }
}
