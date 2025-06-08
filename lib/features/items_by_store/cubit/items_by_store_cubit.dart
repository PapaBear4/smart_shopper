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
        if (currentState is ItemsByStoreLoaded) {
          showCompleted = currentState.showCompletedItems;
        }
        emit(ItemsByStoreLoaded(items, store, showCompletedItems: showCompleted));
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

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    return super.close();
  }
}
