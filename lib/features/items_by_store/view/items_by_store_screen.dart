import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart'; // Added for groupBy
import '../../../models/models.dart';
import '../cubit/items_by_store_cubit.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../common_widgets/error_display.dart';
import '../../../common_widgets/empty_list_widget.dart';
import '../../../common_widgets/standard_list_item.dart';
import '../../shopping_items/widgets/add_edit_shopping_item_dialog.dart'; // Import the dialog

class ItemsByStoreScreen extends StatelessWidget {
  final int storeId;
  const ItemsByStoreScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemsByStoreCubit(storeId: storeId),
      child: const ItemsByStoreView(),
    );
  }
}

class ItemsByStoreView extends StatelessWidget {
  const ItemsByStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>(
          builder: (context, state) {
            if (state is ItemsByStoreLoaded) {
              return Text('Items at ${state.store.name}');
            }
            return const Text('Items by Store');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        actions: [ // Added actions
          BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>(
            builder: (context, state) {
              if (state is ItemsByStoreLoaded) {
                return IconButton(
                  icon: Icon(state.showCompletedItems ? Icons.visibility_off : Icons.visibility), // Changed
                  tooltip: state.showCompletedItems ? 'Hide Completed' : 'Show Completed', // Unchanged, describes action
                  onPressed: () {
                    context.read<ItemsByStoreCubit>().toggleShowCompletedItems();
                  },
                );
              }
              return const SizedBox.shrink(); // Return empty if not loaded
            },
          ),
          BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>( // Added PopupMenuButton
            builder: (context, state) {
              if (state is ItemsByStoreLoaded) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggleGroupByCategory') {
                      context.read<ItemsByStoreCubit>().toggleGroupByCategory();
                    } else if (value == 'toggleGroupByList') {
                      context.read<ItemsByStoreCubit>().toggleGroupByList();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'toggleGroupByCategory',
                      child: Text(state.groupByCategory ? 'Ungroup by Category' : 'Group by Category'),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggleGroupByList',
                      child: Text(state.groupByList ? 'Ungroup by List' : 'Group by List'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>(
        builder: (context, state) {
          if (state is ItemsByStoreLoading || state is ItemsByStoreInitial) {
            return const LoadingIndicator();
          }
          if (state is ItemsByStoreError) {
            return ErrorDisplay(message: state.message);
          }
          if (state is ItemsByStoreLoaded) {
            if (state.items.isEmpty) {
              return const EmptyListWidget(message: 'No items found for this store.');
            }
            
            final itemsToDisplay = state.showCompletedItems
                ? state.items
                : state.items.where((item) => !item.isCompleted).toList();

            if (itemsToDisplay.isEmpty) {
              return const EmptyListWidget(message: 'No active items. Toggle visibility or grouping to see items.');
            }

            if (state.groupByCategory) { // Added grouping logic
              final groupedByCategory = groupBy<ShoppingItem, String>(
                itemsToDisplay,
                (item) => item.category?.isNotEmpty == true ? item.category! : 'Uncategorized', // Handled nullable category
              );
              final sortedCategories = groupedByCategory.keys.toList()..sort();

              if (sortedCategories.isEmpty) {
                 return const EmptyListWidget(message: 'No items to display in categories.');
              }

              return ListView.builder(
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  final itemsInCategory = groupedByCategory[category]!;
                  final activeItemsInCategory = itemsInCategory.where((item) => !item.isCompleted).length;
                  return ExpansionTile(
                    title: Text('$category ($activeItemsInCategory)', style: Theme.of(context).textTheme.titleLarge),
                    initiallyExpanded: true,
                    children: itemsInCategory.map((item) {
                      final listName = item.shoppingList.target?.name;
                      List<Widget> subtitleTexts = [
                        buildDetailText('${item.quantity} ${item.unit ?? ""}'), // Handled nullable unit, category is in header
                      ];
                      if (listName != null && listName.isNotEmpty) {
                        subtitleTexts.add(buildDetailText('List: $listName'));
                      }
                      return Dismissible(
                        key: ObjectKey(item), // Changed from Key('item_\\${item.id}_category_\\${category}')
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          context.read<ItemsByStoreCubit>().deleteItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('\${item.name} deleted')),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: StandardListItem<ShoppingItem>(
                          item: item,
                          onItemTap: (tappedItem) { // Changed onTap to onItemTap
                            _showEditItemDialog(context, tappedItem, context.read<ItemsByStoreCubit>());
                          },
                          onToggleCompletion: (toggledItem) {
                            context.read<ItemsByStoreCubit>().toggleItemCompletion(toggledItem);
                          },
                          subtitleWidgets: subtitleTexts,
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            } else if (state.groupByList) { // Added grouping by list logic
              final groupedByList = groupBy<ShoppingItem, String>(
                itemsToDisplay,
                (item) => item.shoppingList.target?.name ?? 'Unassigned List',
              );
              final sortedLists = groupedByList.keys.toList()..sort();

              if (sortedLists.isEmpty) {
                return const EmptyListWidget(message: 'No items to display in lists.');
              }

              return ListView.builder(
                itemCount: sortedLists.length,
                itemBuilder: (context, index) {
                  final listName = sortedLists[index];
                  final itemsInList = groupedByList[listName]!;
                  final activeItemsInList = itemsInList.where((item) => !item.isCompleted).length;
                  
                  // Get the shopping list ID from the first item in the group
                  // This assumes all items in this group belong to the same list.
                  final shoppingListId = itemsInList.isNotEmpty ? itemsInList.first.shoppingList.target?.id : null;

                  List<Widget> titleWidgets = [
                    Expanded(child: Text('$listName ($activeItemsInList)', style: Theme.of(context).textTheme.titleLarge)),
                  ];

                  if (shoppingListId != null && listName != 'Unassigned List') {
                    titleWidgets.add(
                      IconButton(
                        icon: const Icon(Icons.list_alt),
                        tooltip: 'View $listName',
                        onPressed: () {
                          // Navigate to the shopping list screen
                          // Corrected route based on app_router.dart
                          GoRouter.of(context).push('/list/$shoppingListId');
                        },
                      ),
                    );
                  }

                  return ExpansionTile(
                    title: Row(children: titleWidgets), // Use Row for title to include IconButton
                    initiallyExpanded: true,
                    children: itemsInList.map((item) {
                      List<Widget> subtitleTexts = [
                        buildDetailText('${item.quantity} ${item.unit ?? ""} - ${item.category?.isNotEmpty == true ? item.category : 'Uncategorized'}'), // Handled nullable unit and category
                      ];
                      // List name is in header, so no need to add it to subtitle here
                      return Dismissible(
                        key: ObjectKey(item), // Changed from Key('item_\\${item.id}_list_\\${listName}')
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          context.read<ItemsByStoreCubit>().deleteItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('\${item.name} deleted')),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: StandardListItem<ShoppingItem>(
                          item: item,
                          onItemTap: (tappedItem) { // Changed onTap to onItemTap
                            _showEditItemDialog(context, tappedItem, context.read<ItemsByStoreCubit>());
                          },
                          onToggleCompletion: (toggledItem) {
                            context.read<ItemsByStoreCubit>().toggleItemCompletion(toggledItem);
                          },
                          subtitleWidgets: subtitleTexts,
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            } else {
              // Original ungrouped list view
              return ListView.builder(
                itemCount: itemsToDisplay.length, 
                itemBuilder: (context, index) {
                  final item = itemsToDisplay[index]; 
                  final listName = item.shoppingList.target?.name;
                  List<Widget> subtitleTexts = [
                    buildDetailText('${item.quantity} ${item.unit ?? ""} - ${item.category?.isNotEmpty == true ? item.category : 'Uncategorized'}'), // Handled nullable unit and category
                  ];
                  if (listName != null && listName.isNotEmpty) {
                    subtitleTexts.add(buildDetailText('List: $listName'));
                  }
                  return Dismissible(
                    key: ObjectKey(item), // Changed from Key('item_\\${item.id}_ungrouped')
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      context.read<ItemsByStoreCubit>().deleteItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('\${item.name} deleted')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: StandardListItem<ShoppingItem>(
                      item: item,
                      onItemTap: (tappedItem) { // Changed onTap to onItemTap
                        _showEditItemDialog(context, tappedItem, context.read<ItemsByStoreCubit>());
                      },
                      onToggleCompletion: (toggledItem) {
                        context.read<ItemsByStoreCubit>().toggleItemCompletion(toggledItem);
                      },
                      subtitleWidgets: subtitleTexts,
                    ),
                  );
                },
              );
            }
          }
          return const EmptyListWidget(message: 'Something went wrong.');
        },
      ),
      floatingActionButton: BlocBuilder<ItemsByStoreCubit, ItemsByStoreState>( // Added FAB
        builder: (context, state) {
          if (state is ItemsByStoreLoaded) {
            return FloatingActionButton(
              onPressed: () {
                // Pass the cubit and the current store from the state
                _showAddItemDialog(context, context.read<ItemsByStoreCubit>(), state.store);
              },
              tooltip: 'Add Item to ${state.store.name}',
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink(); // Don't show FAB if not loaded
        },
      ),
    );
  }

  // Helper method to show the edit item dialog
  Future<void> _showEditItemDialog(BuildContext context, ShoppingItem item, ItemsByStoreCubit cubit) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AddEditShoppingItemDialog(
          item: item,
          onPersistItem: (itemToSave) async {
            // Use the cubit from ItemsByStoreScreen to update the item
            await cubit.updateItemDetails(itemToSave);
          },
        );
      },
    );
  }

  // Helper method to show the add item dialog
  Future<void> _showAddItemDialog(BuildContext context, ItemsByStoreCubit cubit, GroceryStore store) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AddEditShoppingItemDialog(
          initialStore: store, // Pass the store
          onPersistItem: (itemToSave) async {
            await cubit.addItem(itemToSave);
          },
        );
      },
    );
  }
}
