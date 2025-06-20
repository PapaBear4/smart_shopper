// This file is part of the ShoppingItemCubit and contains its state definitions.
part of 'shopping_item_cubit.dart';

/// Base class for all states related to the [ShoppingItemCubit].
///
/// It extends [Equatable] to allow for easy comparison between state objects,
/// which is useful for preventing unnecessary UI rebuilds.
abstract class ShoppingItemState extends Equatable {
  const ShoppingItemState();

  /// The list of properties that will be used to determine whether two instances are equal.
  @override
  List<Object?> get props => [];
}

/// The initial state of the cubit before any data has been loaded.
/// The UI can use this state to show a placeholder or an empty screen.
class ShoppingItemInitial extends ShoppingItemState {}

/// The state indicating that shopping items are currently being loaded.
/// The UI should typically display a loading indicator, like a CircularProgressIndicator,
/// when this state is active.
class ShoppingItemLoading extends ShoppingItemState {}

/// The state representing that the shopping items and parent list details have been successfully loaded.
/// This state contains all the necessary data for the UI to display the list of items.
class ShoppingItemLoaded extends ShoppingItemState {
  /// The list of [ShoppingItem] objects for the current shopping list.
  final List<ShoppingItem> items;

  /// The parent [ShoppingList] object, providing context like the list's name for an AppBar title.
  final ShoppingList parentList;

  /// A boolean flag to control the visibility of completed items in the UI.
  final bool showCompletedItems;

  /// A boolean flag to determine if the items should be grouped by their category.
  final bool groupByCategory;

  /// A boolean flag to determine if the items should be grouped by the store where they can be purchased.
  final bool groupByStore;

  /// Constructor for the loaded state.
  ///
  /// [items] and [parentList] are required.
  /// UI behavior flags like [showCompletedItems], [groupByCategory], and [groupByStore]
  /// are optional and default to `false`.
  const ShoppingItemLoaded(
    this.items,
    this.parentList, {
    this.showCompletedItems = false,
    this.groupByCategory = false,
    this.groupByStore = false,
  });

  /// Creates a copy of the current state with some updated values.
  ///
  /// This is a convenient way to create a new state object based on the existing one,
  /// which is useful when only a few properties need to change. For example, when
  /// toggling the `showCompletedItems` flag.
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

  /// Overrides the [props] getter from [Equatable] to include all fields.
  /// This ensures that the state is re-evaluated correctly when any of these properties change.
  @override
  List<Object?> get props => [items, parentList, showCompletedItems, groupByCategory, groupByStore];
}

/// The state representing an error that occurred while fetching or manipulating shopping items.
/// It contains an error message that can be displayed to the user.
class ShoppingItemError extends ShoppingItemState {
  /// The error message describing what went wrong.
  final String message;

  const ShoppingItemError(this.message);

  /// Includes the error message in the props for equality comparison.
  @override
  List<Object?> get props => [message];
}
