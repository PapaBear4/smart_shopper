// Defines the possible states for ShoppingListCubit using the BLoC pattern
part of 'shopping_list_cubit.dart'; // This file is part of the cubit implementation

/// Base abstract class for all shopping list states
/// Using Equatable ensures proper state comparison for BLoC
/// This prevents unnecessary rebuilds when state hasn't actually changed
abstract class ShoppingListState extends Equatable {
  const ShoppingListState();

  // Override props to define what properties determine equality
  // Empty list for base class as it has no properties to compare
  @override
  List<Object> get props => [];
}

/// Initial state when the cubit is first created
/// Used before any data loading has started
class ShoppingListInitial extends ShoppingListState {}

/// Loading state while waiting for repository operations to complete
/// Shown during initial data fetch or when performing CRUD operations
class ShoppingListLoading extends ShoppingListState {}

/// Success state containing the list of shopping lists
/// Emitted when data has been successfully loaded from the repository
class ShoppingListLoaded extends ShoppingListState {
  // The actual shopping list data retrieved from the repository
  final List<ShoppingList> lists;

  const ShoppingListLoaded(this.lists);

  // Override props to include lists in equality comparison
  // This ensures the state is considered changed when the list content changes
  @override
  List<Object> get props => [lists];
}

/// Error state for when operations fail
/// Contains an error message to display to the user
class ShoppingListError extends ShoppingListState {
  // Human-readable error message
  final String message;

  const ShoppingListError(this.message);

  // Include message in equality comparison
  @override
  List<Object> get props => [message];
}