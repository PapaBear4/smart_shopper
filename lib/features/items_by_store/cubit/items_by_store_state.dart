part of 'items_by_store_cubit.dart';

abstract class ItemsByStoreState extends Equatable {
  const ItemsByStoreState();

  @override
  List<Object?> get props => [];
}

class ItemsByStoreInitial extends ItemsByStoreState {}

class ItemsByStoreLoading extends ItemsByStoreState {}

class ItemsByStoreLoaded extends ItemsByStoreState {
  final List<ShoppingItem> items;
  final GroceryStore store; // To display store name or other details
  final bool showCompletedItems; // Added flag
  final bool groupByCategory; // Added flag
  final bool groupByList; // Added flag for grouping by list

  const ItemsByStoreLoaded(
    this.items,
    this.store, {
    this.showCompletedItems = true, // Default to true
    this.groupByCategory = true, // Default to true
    this.groupByList = false, // Default to false
  });

  @override
  List<Object?> get props => [items, store, showCompletedItems, groupByCategory, groupByList]; // Updated props

  // Helper to copyWith new state
  ItemsByStoreLoaded copyWith({
    List<ShoppingItem>? items,
    GroceryStore? store,
    bool? showCompletedItems,
    bool? groupByCategory, // Added
    bool? groupByList, // Added
  }) {
    return ItemsByStoreLoaded(
      items ?? this.items,
      store ?? this.store,
      showCompletedItems: showCompletedItems ?? this.showCompletedItems,
      groupByCategory: groupByCategory ?? this.groupByCategory, // Added
      groupByList: groupByList ?? this.groupByList, // Added
    );
  }
}

class ItemsByStoreError extends ItemsByStoreState {
  final String message;

  const ItemsByStoreError(this.message);

  @override
  List<Object?> get props => [message];
}
