// lib/features/shopping_lists/cubit/shopping_list_state.dart
part of 'shopping_list_cubit.dart'; // Link to the cubit file

// Using sealed class for states can be beneficial, but simple classes work too
abstract class ShoppingListState extends Equatable {
  const ShoppingListState();

  @override
  List<Object> get props => [];
}

class ShoppingListInitial extends ShoppingListState {}

class ShoppingListLoading extends ShoppingListState {}

class ShoppingListLoaded extends ShoppingListState {
  final List<ShoppingList> lists;

  const ShoppingListLoaded(this.lists);

  @override
  List<Object> get props => [lists];
}

class ShoppingListError extends ShoppingListState {
  final String message;

  const ShoppingListError(this.message);

  @override
  List<Object> get props => [message];
}