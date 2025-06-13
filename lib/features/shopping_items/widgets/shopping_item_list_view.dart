import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // For groupBy
import 'package:intl/intl.dart'; // For DateFormat
import 'package:go_router/go_router.dart'; // Added for navigation

import '../../../models/models.dart';
import '../cubit/shopping_item_cubit.dart';
import 'add_edit_shopping_item_dialog.dart'; // For potential tap action
import '../../../common_widgets/loading_indicator.dart'; 
import '../../../common_widgets/error_display.dart'; 
import '../../../common_widgets/empty_list_widget.dart'; 
import '../../../common_widgets/standard_list_item.dart'; // Added


class ShoppingItemListView extends StatelessWidget {
  const ShoppingItemListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
      builder: (context, state) {
        if (state is ShoppingItemLoading) {
          return const LoadingIndicator(); 
        } else if (state is ShoppingItemLoaded) {
          final filteredItems = state.showCompletedItems
              ? state.items
              : state.items.where((item) => !item.isCompleted).toList();

          if (filteredItems.isEmpty) {
            
            return const EmptyListWidget(message: 'No items in this list yet. Add one or adjust filters!');
          }

          if (state.groupByCategory) {
            // Group items by category
            final groupedByCategory = groupBy<ShoppingItem, String>(
              filteredItems,
              (item) => item.category?.isNotEmpty == true ? item.category! : 'Uncategorized',
            );

            // Sort categories alphabetically
            final sortedCategories = groupedByCategory.keys.toList()..sort();

            return ListView.builder(
              itemCount: sortedCategories.length, // Use sorted categories
              itemBuilder: (context, index) {
                final category = sortedCategories[index]; // Use sorted categories
                final itemsInCategory = groupedByCategory[category]!;
                final activeItemsInCategory = itemsInCategory.where((item) => !item.isCompleted).length;
                return ExpansionTile(
                  title: Text('$category ($activeItemsInCategory)', style: Theme.of(context).textTheme.titleLarge),
                  initiallyExpanded: true,
                  // Map items in category to StandardListItem
                  children: itemsInCategory.map((item) => _buildItemTile(context, item, state)).toList(), 
                );
              },
            );
          } else if (state.groupByStore) {
            // Group items by store logic
            final Map<int?, List<ShoppingItem>> itemsGroupedByStoreId = {};
            final Map<int, GroceryStore> storeIdToStoreObject = {};

            for (var item in filteredItems) {
              GroceryStore? determinedStore;
              if (item.priceEntries.isNotEmpty) {
                List<PriceEntry> validPriceEntries = item.priceEntries
                    .where((pe) => pe.groceryStore.target != null && pe.price > 0)
                    .toList();
                if (validPriceEntries.isNotEmpty) {
                  validPriceEntries.sort((a, b) {
                    return a.price.compareTo(b.price);
                  });
                  determinedStore = validPriceEntries.first.groceryStore.target;
                }
              }
              if (determinedStore == null && item.groceryStores.isNotEmpty) {
                determinedStore = item.groceryStores.first;
              }

              final storeIdKey = determinedStore?.id;
              if (determinedStore != null) {
                storeIdToStoreObject.putIfAbsent(determinedStore.id, () => determinedStore!);
              }
              // The item comes from filteredItems, which is already filtered by showCompletedItems.
              // So, every item here should be added to its respective store group.
              // The filtering of store groups themselves (whether to display a store group or not)
              // happens later with storeKeysWithActiveItems.
              itemsGroupedByStoreId.putIfAbsent(storeIdKey, () => []).add(item);
            }

            // Filter out store groups that have no active items if showCompletedItems is false
            final List<int?> storeKeysWithActiveItems = itemsGroupedByStoreId.keys.where((storeIdKey) {
              final itemsInStore = itemsGroupedByStoreId[storeIdKey]!;
              final activeItemsCount = itemsInStore.where((item) => !item.isCompleted).length;
              // If showing completed items, all groups are valid if they have any items at all.
              // If not showing completed items, only groups with active items are valid.
              return state.showCompletedItems ? itemsInStore.isNotEmpty : activeItemsCount > 0;
            }).toList();

            final List<int?> sortedStoreIdKeys = storeKeysWithActiveItems
              ..sort((a, b) {
                if (a == null) return 1; // Null (No Specific Store) at the end
                if (b == null) return -1;
                final storeA = storeIdToStoreObject[a]?.name ?? '';
                final storeB = storeIdToStoreObject[b]?.name ?? '';
                return storeA.toLowerCase().compareTo(storeB.toLowerCase());
              });

            return ListView.builder(
              itemCount: sortedStoreIdKeys.length,
              itemBuilder: (context, index) {
                final storeIdKey = sortedStoreIdKeys[index];
                final itemsInStore = itemsGroupedByStoreId[storeIdKey]!;
                // Recalculate activeItemsInStore based on the potentially filtered itemsInStore list for this specific key
                final activeItemsInStore = itemsInStore.where((item) => !item.isCompleted).length;
                final storeName = storeIdKey == null ? 'No Specific Store' : storeIdToStoreObject[storeIdKey]!.name;

                // If not showing completed items and this store has no active items, don't build the ExpansionTile
                // This check is now implicitly handled by `storeKeysWithActiveItems` but an explicit check on activeItemsInStore
                // before building the ExpansionTile can be an additional safeguard if needed, though ideally
                // sortedStoreIdKeys should already be filtered correctly.
                // However, the count in the title ($activeItemsInStore) should reflect the active items.

                List<Widget> titleWidgets = [
                  Expanded(
                    child: Text(
                      '$storeName ($activeItemsInStore)',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ];

                if (storeIdKey != null) {
                  titleWidgets.add(
                    IconButton(
                      icon: const Icon(Icons.storefront), // Changed to storefront icon
                      tooltip: 'View all items at $storeName',
                      onPressed: () {
                        // Ensure this route matches your GoRouter configuration for ItemsByStoreScreen
                        GoRouter.of(context).push('/stores/$storeIdKey/items');
                      },
                    ),
                  );
                }

                return ExpansionTile(
                  title: Row(children: titleWidgets), // Changed to Row
                  initiallyExpanded: true,
                  children: itemsInStore.map((item) => _buildItemTile(context, item, state)).toList(),
                );
              },
            );
          } else {
            // UNGROUPED VIEW
            return ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildItemTile(context, item, state);
              },
            );
          }
        } else if (state is ShoppingItemError) {
          return ErrorDisplay(message: state.message); 
        }
        
        return const EmptyListWidget(message: 'Press + to add an item.');
      },
    );
  }

  // _buildDetailText is now available globally from standard_list_item.dart if needed elsewhere,
  // or keep it local if only used for the specific subtitle structure here.
  // For this refactor, we assume _buildItemDetailsList will provide the subtitle widgets.

  Widget _buildItemTile(BuildContext context, ShoppingItem item, ShoppingItemLoaded currentState) {
    String titleText = item.name;
    // Always show quantity and unit if unit is present, or if quantity is not 1.0
    if (item.unit?.isNotEmpty == true || item.quantity != 1.0) {
      String qtyString = item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1);
      String unitString = item.unit?.trim() ?? "";
      String details = qtyString;
      if (unitString.isNotEmpty) {
        details += " $unitString";
      }
      titleText += ' ($details)'; // Ensure space is before the parenthesis and not trimmed
    }

    return StandardListItem<ShoppingItem>(
      item: item,
      titleText: titleText, // Use the new titleText
      onToggleCompletion: (toggledItem) {
        context.read<ShoppingItemCubit>().toggleItemCompletion(toggledItem);
      },
      onItemTap: (tappedItem) {
        showDialog(
          context: context,
          builder: (_) => AddEditShoppingItemDialog(
            item: tappedItem, // Pass the item to edit
            // shoppingItemCubit: context.read<ShoppingItemCubit>(), // OLD
            onPersistItem: (itemToSave) async {
              // Call the cubit's updateItem method
              await context.read<ShoppingItemCubit>().updateItem(itemToSave);
            },
          ),
        );
      },
      onDismissed: (dismissedItem) {
        context.read<ShoppingItemCubit>().deleteItem(dismissedItem.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${dismissedItem.name} deleted')),
        );
      },
      subtitleWidgets: _buildItemDetailsList(context, item, currentState),
    );
  }

  List<Widget> _buildItemDetailsList(BuildContext context, ShoppingItem item, ShoppingItemLoaded currentState) {
    List<Widget> detailsWidgets = [];

    // Item Name, Quantity and Unit are now handled by StandardListItem title

    // Desired Attributes
    if (item.desiredAttributes.isNotEmpty) {
      detailsWidgets.add(buildDetailText('Wants: ${item.desiredAttributes.join(', ')}'));
    }

    // Determine best price entry
    PriceEntry? bestPriceEntry;
    if (item.priceEntries.isNotEmpty) {
      List<PriceEntry> validPriceEntries = item.priceEntries
          .where((pe) => pe.groceryStore.target != null && pe.price > 0)
          .toList();
      if (validPriceEntries.isNotEmpty) {
        validPriceEntries.sort((a, b) {
          int priceCompare = a.price.compareTo(b.price);
          if (priceCompare != 0) return priceCompare;
          int dateCompare = b.date.compareTo(a.date); // most recent
          if (dateCompare != 0) return dateCompare;
          return a.groceryStore.target!.name.toLowerCase().compareTo(b.groceryStore.target!.name.toLowerCase());
        });
        bestPriceEntry = validPriceEntries.first;
      }
    }

    // Conditional details based on grouping
    if (!currentState.groupByCategory && !currentState.groupByStore) { // UNGROUPED
      if (item.category?.isNotEmpty == true) {
        detailsWidgets.add(buildDetailText('Category: ${item.category}'));
      }
      if (bestPriceEntry != null) {
        detailsWidgets.add(buildDetailText(
            'Price: ${bestPriceEntry.price.toStringAsFixed(2)} at ${bestPriceEntry.groceryStore.target!.name} (${DateFormat('MM/dd/yy').format(bestPriceEntry.date)})'));
      } else if (item.groceryStores.isNotEmpty) {
        detailsWidgets.add(buildDetailText('Stores: ${item.groceryStores.map((s) => s.name).join(', ')}'));
      }
    } else if (currentState.groupByCategory) { // GROUPED BY CATEGORY
      // Category is in header
      if (bestPriceEntry != null) {
        detailsWidgets.add(buildDetailText(
            'Price: ${bestPriceEntry.price.toStringAsFixed(2)} at ${bestPriceEntry.groceryStore.target!.name} (${DateFormat('MM/dd/yy').format(bestPriceEntry.date)})'));
      } else if (item.groceryStores.isNotEmpty) {
        detailsWidgets.add(buildDetailText('Stores: ${item.groceryStores.map((s) => s.name).join(', ')}'));
      }
    } else if (currentState.groupByStore) { // GROUPED BY STORE
      // Store is in header
      if (item.category?.isNotEmpty == true) {
        detailsWidgets.add(buildDetailText('Category: ${item.category}'));
      }
      if (bestPriceEntry != null && bestPriceEntry.groceryStore.target != null) {
          // Check if the best price store is different from the group header store
          // This requires knowing the current group store, which is not directly passed here.
          // For simplicity, we'll show the full price detail. If the group header IS the best price store, it might be redundant.
          detailsWidgets.add(buildDetailText('Price: ${bestPriceEntry.price.toStringAsFixed(2)} (${DateFormat('MM/dd/yy').format(bestPriceEntry.date)})'));
      }
    }
    return detailsWidgets;
  }
}
