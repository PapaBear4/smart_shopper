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

  const ItemsByStoreLoaded(this.items, this.store, {this.showCompletedItems = true}); // Default to true

  @override
  List<Object?> get props => [items, store, showCompletedItems]; // Updated props

  // Helper to copyWith new state
  ItemsByStoreLoaded copyWith({
    List<ShoppingItem>? items,
    GroceryStore? store,
    bool? showCompletedItems,
  }) {
    return ItemsByStoreLoaded(
      items ?? this.items,
      store ?? this.store,
      showCompletedItems: showCompletedItems ?? this.showCompletedItems,
    );
  }
}

class ItemsByStoreError extends ItemsByStoreState {
  final String message;

  const ItemsByStoreError(this.message);

  @override
  List<Object?> get props => [message];
}
