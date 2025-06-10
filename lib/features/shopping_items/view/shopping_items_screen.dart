// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/features/shopping_items/cubit/shopping_item_cubit.dart';
import 'package:smart_shopper/features/shopping_items/widgets/add_edit_shopping_item_dialog.dart';
import 'package:smart_shopper/features/shopping_items/widgets/shopping_item_list_view.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart'; // Ensure this import is present
import 'package:smart_shopper/service_locator.dart';
import '../../../common_widgets/loading_indicator.dart'; 
import '../../../common_widgets/error_display.dart'; 

class ShoppingItemsScreen extends StatelessWidget {
  final int listId; // Received from the router

  const ShoppingItemsScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit. We create it manually here, passing the listId
    // and fetching the repository from GetIt.
    return BlocProvider(
      create:
          (context) => ShoppingItemCubit(
            repository: getIt<IShoppingItemRepository>(), // Get repo from DI
            listId: listId, // Pass the listId from the route
          ),
      child: ShoppingItemView(), // Use a separate widget for the view content
    );
  }
}

// Separate View widget to easily access the Cubit context below the provider
class ShoppingItemView extends StatelessWidget {
  const ShoppingItemView({super.key});
  @override
  // WIDGET FOR THE LIST ITSELF
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
          builder: (context, state) {
            if (state is ShoppingItemLoaded) {
              final uncheckedItems = state.items.where((item) => !item.isCompleted).length;
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      state.parentList.name, // Display list name
                      overflow: TextOverflow.ellipsis, // Truncate if too long
                    ),
                  ),
                  Text(' ($uncheckedItems)'), // Display count
                ],
              );
            }
            return const Text('Shopping Items'); // Default or loading title
          },
        ),
        actions: [
          BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
            builder: (context, state) {
              if (state is ShoppingItemLoaded) {
                return IconButton(
                  icon: Icon(state.showCompletedItems ? Icons.visibility : Icons.visibility_off),
                  tooltip: state.showCompletedItems ? 'Hide Completed' : 'Show Completed',
                  onPressed: () {
                    context.read<ShoppingItemCubit>().toggleShowCompletedItems();
                  },
                );
              }
              return const SizedBox.shrink(); // Return empty if not loaded
            },
          ),
          BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
            builder: (context, state) {
              if (state is ShoppingItemLoaded) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'groupByCategory') {
                      context.read<ShoppingItemCubit>().toggleGroupByCategory();
                    } else if (value == 'groupByStore') {
                      context.read<ShoppingItemCubit>().toggleGroupByStore();
                    } else if (value == 'uncheckAll') {
                      context.read<ShoppingItemCubit>().uncheckAllItems();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'groupByCategory',
                      child: Text(state.groupByCategory ? 'Ungroup by Category' : 'Group by Category'),
                    ),
                    PopupMenuItem<String>(
                      value: 'groupByStore',
                      child: Text(state.groupByStore ? 'Ungroup by Store' : 'Group by Store'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'uncheckAll',
                      child: Text('Uncheck All Items'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink(); // Return empty if not loaded
            },
          ),
        ],
      ),
      body: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
        builder: (context, state) {
          if (state is ShoppingItemLoading) {
            return const LoadingIndicator(); 
          } else if (state is ShoppingItemLoaded) {
            return const ShoppingItemListView();
          } else if (state is ShoppingItemError) {
            return ErrorDisplay(message: state.message); 
          }
          return const Center(child: Text('Loading items...')); 
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddEditShoppingItemDialog(
              shoppingListIdForNewItem: context.read<ShoppingItemCubit>().listId, // Pass the current listId
              onPersistItem: (item) async {
                await context.read<ShoppingItemCubit>().addItem(item);
              },
            ),
          );
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
