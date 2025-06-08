import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // For groupBy

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
            return Center(
              child: Text(
                state.showCompletedItems
                    ? 'No items yet. Add some!'
                    : 'No active items. Add some or show completed items.',
              ),
            );
          }

          if (state.groupByCategory) {
            // Group items by category
            final groupedItems = groupBy(
                filteredItems, (ShoppingItem item) => item.category.isNotEmpty ? item.category : 'Uncategorized');

            // Sort categories (optional, but good for consistency)
            final sortedCategories = groupedItems.keys.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            
            // If 'Uncategorized' exists, move it to the end
            if (sortedCategories.contains('Uncategorized')) {
              sortedCategories.remove('Uncategorized');
              sortedCategories.add('Uncategorized');
            }

            return ListView.builder(
              itemCount: sortedCategories.length,
              itemBuilder: (context, categoryIndex) {
                final category = sortedCategories[categoryIndex];
                final itemsInCategory = groupedItems[category]!;
                // Sort items within the category by name (already handled by repository sort, but good for explicitness if needed)
                // itemsInCategory.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true, // Important for nested ListViews
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                      itemCount: itemsInCategory.length,
                      itemBuilder: (context, itemIndex) {
                        final item = itemsInCategory[itemIndex];
                        return _buildItemTile(context, item);
                      },
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    if (categoryIndex < sortedCategories.length -1) // Add a thicker divider between categories
                       Divider(height: 8, thickness: 4, color: Colors.grey.shade300),
                  ],
                );
              },
            );
          } else {
            // Original flat list view
            return ListView.separated(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildItemTile(context, item);
              },
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey.shade200,
              ),
            );
          }
        } else if (state is ShoppingItemError) {
          return Center(child: Text('Error: \${state.message}'));
        }
        return const Center(child: Text('Press + to add an item.'));
      },
    );
  }

  Widget _buildItemTile(BuildContext context, ShoppingItem item) {
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
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 17,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          color: item.isCompleted ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      // When grouped, category is already a header, so don't show it here
                      // Only show quantity and unit if meaningful
                      if (item.quantity != 1 || item.unit.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 2.0),
                           child: Text(
                            '${item.quantity} ${item.unit}', // Removed backslashes
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                                                   ),
                         ),
                    ],
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
}
