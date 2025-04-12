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

  const ShoppingItemLoaded(this.items, this.parentList);

  @override
  List<Object?> get props => [items, parentList];
}

// State for handling errors
class ShoppingItemError extends ShoppingItemState {
  final String message;

  const ShoppingItemError(this.message);

  @override
  List<Object?> get props => [message];
}