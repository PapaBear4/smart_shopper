import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // For groupBy
import 'package:intl/intl.dart'; // For DateFormat

import '../../../models/models.dart';
import '../cubit/shopping_item_cubit.dart';
import 'add_edit_shopping_item_dialog.dart';

class ShoppingItemListView extends StatelessWidget {
  const ShoppingItemListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
      builder: (context, state) {
        if (state is ShoppingItemLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ShoppingItemLoaded) {
          final filteredItems = state.showCompletedItems
              ? state.items
              : state.items.where((item) => !item.isCompleted).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text('No items in this list yet!'));
          }

          if (state.groupByCategory) {
            // Group items by category
            final groupedByCategory = groupBy<ShoppingItem, String>(
              filteredItems,
              (item) => item.category.isNotEmpty ? item.category : 'Uncategorized',
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
                  children: itemsInCategory.map((item) => _buildItemTile(context, item, state)).toList(),
                );
              },
            );
          } else if (state.groupByStore) {
            // Group items by store: 
            // 1. Best store by price (if price data available)
            // 2. Directly linked stores (if no price data, from item.groceryStores)
            // 3. "No Specific Store" (if neither of the above)
            final Map<int?, List<ShoppingItem>> itemsGroupedByStoreId = {}; // Key is store ID, or null
            final Map<int, GroceryStore> storeIdToStoreObject = {}; // To get store object from ID

            for (var item in filteredItems) {
              GroceryStore? determinedStore;

              // 1. Try to determine store from price data
              if (item.priceEntries.isNotEmpty) {
                List<PriceEntry> validPriceEntries = item.priceEntries
                    .where((pe) => pe.groceryStore.target != null && pe.price > 0)
                    .toList();

                if (validPriceEntries.isNotEmpty) {
                  validPriceEntries.sort((a, b) {
                    int priceCompare = a.price.compareTo(b.price);
                    if (priceCompare != 0) return priceCompare;
                    int dateCompare = b.date.compareTo(a.date);
                    if (dateCompare != 0) return dateCompare;
                    return a.groceryStore.target!.name.toLowerCase().compareTo(b.groceryStore.target!.name.toLowerCase());
                  });
                  determinedStore = validPriceEntries.first.groceryStore.target;
                }
              }

              // 2. If no store from price data, try direct links
              if (determinedStore == null && item.groceryStores.isNotEmpty) {
                // If multiple direct stores, this logic will add the item to the first one for grouping purposes.
                // The problem description implies an item should appear under *one* group when grouped by store.
                // If it should appear under *all* directly linked stores when no price data, this part needs adjustment.
                // For now, let's assume it groups under the *first* directly linked store if no price data.
                determinedStore = item.groceryStores.first;
              }

              // Add to the appropriate group
              final storeIdKey = determinedStore?.id;
              itemsGroupedByStoreId.putIfAbsent(storeIdKey, () => []).add(item);
              if (determinedStore != null && !storeIdToStoreObject.containsKey(storeIdKey)) {
                storeIdToStoreObject[storeIdKey!] = determinedStore;
              }
            }

            // Sort store keys (IDs) alphabetically by store name, with null (No Specific Store) at the end
            final List<int?> sortedStoreIdKeys = itemsGroupedByStoreId.keys.toList()
              ..sort((aId, bId) {
                if (aId == null && bId == null) return 0;
                if (aId == null) return 1; // nulls go last
                if (bId == null) return -1; // nulls go last
                
                final storeA = storeIdToStoreObject[aId]!;
                final storeB = storeIdToStoreObject[bId]!;
                return storeA.name.toLowerCase().compareTo(storeB.name.toLowerCase());
              });

            return ListView.builder(
              itemCount: sortedStoreIdKeys.length,
              itemBuilder: (context, index) {
                final storeIdKey = sortedStoreIdKeys[index];
                final itemsInGroup = itemsGroupedByStoreId[storeIdKey]!;
                final activeItemsInGroup = itemsInGroup.where((item) => !item.isCompleted).length;
                final groupTitle = storeIdKey != null ? storeIdToStoreObject[storeIdKey]!.name : 'No Specific Store';

                // Sort items within each group by completion status, then by name
                itemsInGroup.sort((a, b) {
                  // Primary sort: completion status (incomplete first)
                  if (a.isCompleted && !b.isCompleted) {
                    return 1; // a (completed) comes after b (incomplete)
                  } else if (!a.isCompleted && b.isCompleted) {
                    return -1; // a (incomplete) comes before b (completed)
                  }
                  // Secondary sort: item name (alphabetically)
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });

                return ExpansionTile(
                  title: Text('$groupTitle ($activeItemsInGroup)', style: Theme.of(context).textTheme.titleLarge),
                  initiallyExpanded: true,
                  children: itemsInGroup.map((item) => _buildItemTile(context, item, state)).toList(),
                );
              },
            );
          } else {
            // Display items as a flat list, sorted by completion status then name
            return ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildItemTile(context, item, state);
              },
            );
          }
        } else if (state is ShoppingItemError) {
          return Center(child: Text('Error: \${state.message}'));
        }
        return const Center(child: Text('Press + to add an item.'));
      },
    );
  }

  Widget _buildDetailText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, ShoppingItem item, ShoppingItemLoaded currentState) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        context.read<ShoppingItemCubit>().deleteItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\${item.name} deleted')),
        );
      },
      background: Container(
        color: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Optional: Navigate to item details or quick edit
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (bool? value) {
                    if (value != null) {
                      context.read<ShoppingItemCubit>().toggleItemCompletion(item);
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildItemDetailsList(context, item, currentState),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey.shade700),
                  tooltip: 'Edit Item',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddEditShoppingItemDialog(
                        item: item,
                        shoppingItemCubit: context.read<ShoppingItemCubit>(),
                      ),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemDetailsList(BuildContext context, ShoppingItem item, ShoppingItemLoaded currentState) {
    List<Widget> detailsWidgets = [];

    // Item Name
    detailsWidgets.add(
      Text(
        item.name,
        style: TextStyle(
          fontSize: 17,
          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          color: item.isCompleted ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );

    // Quantity and Unit
    if (item.quantity != 1 || item.unit.isNotEmpty) {
      detailsWidgets.add(_buildDetailText('${item.quantity} ${item.unit}'));
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
      if (item.category.isNotEmpty) {
        detailsWidgets.add(_buildDetailText('Category: ${item.category}'));
      }
      if (bestPriceEntry != null) {
        detailsWidgets.add(_buildDetailText(
            'Price: ${bestPriceEntry.price.toStringAsFixed(2)} at ${bestPriceEntry.groceryStore.target!.name} (${DateFormat('MM/dd/yy').format(bestPriceEntry.date)})'));
      } else if (item.groceryStores.isNotEmpty) {
        detailsWidgets.add(_buildDetailText('Stores: ${item.groceryStores.map((s) => s.name).join(', ')}'));
      }
    } else if (currentState.groupByCategory) { // GROUPED BY CATEGORY
      // Category is in header
      if (bestPriceEntry != null) {
        detailsWidgets.add(_buildDetailText(
            'Price: ${bestPriceEntry.price.toStringAsFixed(2)} at ${bestPriceEntry.groceryStore.target!.name} (${DateFormat('MM/dd/yy').format(bestPriceEntry.date)})'));
      } else if (item.groceryStores.isNotEmpty) {
        detailsWidgets.add(_buildDetailText('Stores: ${item.groceryStores.map((s) => s.name).join(', ')}'));
      }
    } else if (currentState.groupByStore) { // GROUPED BY STORE
      // Store is in header
      if (item.category.isNotEmpty) {
        detailsWidgets.add(_buildDetailText('Category: ${item.category}'));
      }
      if (bestPriceEntry != null) {
        // The store in bestPriceEntry is the group header store
        detailsWidgets.add(_buildDetailText('Price: ${bestPriceEntry.price.toStringAsFixed(2)} (${DateFormat('MM/dd/yy').format(bestPriceEntry.date)})'));
      }
    }
    return detailsWidgets;
  }
}
