part of 'shopping_item_cubit.dart'; // Link to the cubit file

abstract class ShoppingItemState extends Equatable {
  const ShoppingItemState();

  @override
  List<Object?> get props => [];
}

class ShoppingItemInitial extends ShoppingItemState {}

class ShoppingItemLoading extends ShoppingItemState {}

// State when items (and the parent list details) are successfully loaded
class ShoppingItemLoaded extends ShoppingItemState {
  final List<ShoppingItem> items;
  final ShoppingList parentList; // Include parent list for context (e.g., AppBar title)
  final bool showCompletedItems; // New field
  final bool groupByCategory; // New field for grouping
  final bool groupByStore; // New field for grouping by store

  const ShoppingItemLoaded(
    this.items,
    this.parentList, {
    this.showCompletedItems = false, // Default to false
    this.groupByCategory = false, // Default to false
    this.groupByStore = false, // Default to false
  });

  // Helper to create a new state with modified showCompletedItems
  ShoppingItemLoaded copyWith({
    List<ShoppingItem>? items,
    ShoppingList? parentList,
    bool? showCompletedItems,
    bool? groupByCategory,
    bool? groupByStore,
  }) {
    return ShoppingItemLoaded(
      items ?? this.items,
      parentList ?? this.parentList,
      showCompletedItems: showCompletedItems ?? this.showCompletedItems,
      groupByCategory: groupByCategory ?? this.groupByCategory,
      groupByStore: groupByStore ?? this.groupByStore,
    );
  }

  @override
  List<Object?> get props => [items, parentList, showCompletedItems, groupByCategory, groupByStore];
}

// State for handling errors
class ShoppingItemError extends ShoppingItemState {
  final String message;

  const ShoppingItemError(this.message);

  @override
  List<Object?> get props => [message];
}