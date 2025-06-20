// Import necessary libraries for async, Bloc, and Equatable.
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Import data models and the repository for data access.
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart';

// Link to the state definition file.
part 'shopping_item_state.dart';

/// Manages the state for the shopping items view.
///
/// This Cubit is responsible for fetching, adding, updating, and deleting shopping items
/// for a specific shopping list. It interacts with the [IShoppingItemRepository]
/// to perform data operations and emits different [ShoppingItemState]s to notify the UI of changes.
class ShoppingItemCubit extends Cubit<ShoppingItemState> {
  final IShoppingItemRepository _repository;
  final int listId; // The ID of the shopping list being managed.
  StreamSubscription? _itemSubscription; // Subscription to the item data stream.
  ShoppingList? _parentList; // Cache for the parent shopping list details.

  /// Constructor for the cubit.
  ///
  /// Requires a repository instance and the ID of the shopping list.
  /// It starts in the [ShoppingItemInitial] state and immediately
  /// calls [loadInitialData] to fetch the necessary information.
  ShoppingItemCubit({
    required IShoppingItemRepository repository,
    required this.listId,
  })  : _repository = repository,
        super(ShoppingItemInitial()) {
    loadInitialData();
  }

  /// Fetches the parent shopping list details and subscribes to the item stream.
  ///
  /// This method is called upon initialization to load the necessary data.
  /// It first emits a [ShoppingItemLoading] state. Then, it fetches the parent
  /// shopping list's details. If successful, it subscribes to the stream of
  /// items for that list and emits a [ShoppingItemLoaded] state with the data.
  /// If any step fails, it emits a [ShoppingItemError] state.
  Future<void> loadInitialData() async {
    emit(ShoppingItemLoading());
    try {
      // First, get the details of the parent shopping list.
      _parentList = await _repository.getShoppingList(listId);
      if (_parentList == null) {
        emit(const ShoppingItemError("Parent shopping list not found."));
        return;
      }

      // Cancel any existing subscription to avoid memory leaks.
      _itemSubscription?.cancel();
      // Subscribe to the stream of shopping items for this list.
      _itemSubscription = _repository.getItemsStream(listId).listen(
        (items) {
          // When new item data is received from the stream.
          if (_parentList != null) {
            // Preserve the UI display settings (like showCompleted, groupBy) across reloads.
            final bool showCompleted = state is ShoppingItemLoaded
                ? (state as ShoppingItemLoaded).showCompletedItems
                : false;
            final bool groupingByCategory = state is ShoppingItemLoaded
                ? (state as ShoppingItemLoaded).groupByCategory
                : false;
            final bool groupingByStore = state is ShoppingItemLoaded
                ? (state as ShoppingItemLoaded).groupByStore
                : false;

            // Emit the loaded state with the new items and cached list details.
            emit(ShoppingItemLoaded(
              items,
              _parentList!,
              showCompletedItems: showCompleted,
              groupByCategory: groupingByCategory,
              groupByStore: groupingByStore,
            ));
          } else {
            // This is an unlikely edge case but handled for safety.
            emit(const ShoppingItemError("Parent list data lost."));
          }
        },
        onError: (error) {
          // Handle any errors from the stream.
          emit(ShoppingItemError("Failed to load items: $error"));
        },
      );
    } catch (e) {
      // Handle errors during the initial data fetch.
      emit(ShoppingItemError("Failed to initialize item view: $e"));
    }
  }

  /// Adds a new shopping item to the list.
  Future<void> addItem(ShoppingItem item) async {
    try {
      // The repository handles associating the item with the correct listId.
      await _repository.addItem(item, listId);
      // The UI will update automatically via the stream subscription.
    } catch (e) {
      emit(ShoppingItemError("Failed to add item: $e"));
    }
  }

  /// Updates an existing shopping item.
  Future<void> updateItem(ShoppingItem item) async {
    try {
      await _repository.updateItem(item);
      // UI updates automatically via the stream.
    } catch (e) {
      emit(ShoppingItemError("Failed to update item: $e"));
    }
  }

  /// Toggles the completion status of a shopping item.
  Future<void> toggleItemCompletion(ShoppingItem item) async {
    // Create a new ShoppingItem instance with the flipped `isCompleted` value.
    final updatedItem = ShoppingItem(
      id: item.id, // Must preserve the ID for the update to work.
      name: item.name,
      category: item.category,
      quantity: item.quantity,
      unit: item.unit,
      isCompleted: !item.isCompleted, // The toggled value.
    )
      // It's crucial to preserve relationships when updating.
      ..shoppingList.targetId = item.shoppingList.targetId;
    updatedItem.groceryStores.addAll(item.groceryStores);

    await updateItem(updatedItem); // Use the general update method.
  }

  /// Deletes a shopping item by its ID.
  Future<void> deleteItem(int itemId) async {
    try {
      await _repository.deleteItem(itemId);
      // UI updates automatically via the stream.
    } catch (e) {
      emit(ShoppingItemError("Failed to delete item: $e"));
    }
  }

  /// Toggles the visibility of completed items in the UI.
  void toggleShowCompletedItems() {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      // Emit a new state with the toggled boolean value.
      emit(currentState.copyWith(showCompletedItems: !currentState.showCompletedItems));
    }
  }

  /// Toggles grouping by category.
  void toggleGroupByCategory() {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      // When grouping by category, disable grouping by store.
      emit(currentState.copyWith(groupByCategory: !currentState.groupByCategory, groupByStore: false));
    }
  }

  /// Toggles grouping by store.
  void toggleGroupByStore() {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      // When grouping by store, disable grouping by category.
      emit(currentState.copyWith(groupByStore: !currentState.groupByStore, groupByCategory: false));
    }
  }

  /// Unchecks all completed items in the list.
  Future<void> uncheckAllItems() async {
    if (state is ShoppingItemLoaded) {
      final currentState = state as ShoppingItemLoaded;
      // Create a list of items that need to be updated.
      List<ShoppingItem> itemsToUpdate = [];
      for (var item in currentState.items) {
        if (item.isCompleted) {
          // Create an updated copy with isCompleted set to false.
          final updatedItem = ShoppingItem(
            id: item.id,
            name: item.name,
            category: item.category,
            quantity: item.quantity,
            unit: item.unit,
            isCompleted: false, // Uncheck the item.
          )
            // Preserve all relationships.
            ..shoppingList.targetId = item.shoppingList.targetId
            ..brand.targetId = item.brand.targetId;
          updatedItem.groceryStores.addAll(item.groceryStores);
          itemsToUpdate.add(updatedItem);
        }
      }
      // If there are items to update, send them to the repository in a batch.
      if (itemsToUpdate.isNotEmpty) {
        try {
          await _repository.updateItems(itemsToUpdate);
          // UI will update via the stream.
        } catch (e) {
          emit(ShoppingItemError("Failed to uncheck all items: $e"));
        }
      }
    }
  }

  /// Cleans up resources when the Cubit is closed.
  @override
  Future<void> close() {
    // Cancel the stream subscription to prevent memory leaks.
    _itemSubscription?.cancel();
    return super.close();
  }
}
