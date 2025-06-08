// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/features/shopping_items/cubit/shopping_item_cubit.dart';
import 'package:smart_shopper/features/shopping_items/widgets/add_edit_shopping_item_dialog.dart';
import 'package:smart_shopper/features/shopping_items/widgets/shopping_item_list_view.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/service_locator.dart';

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
              return Text(state.parentList.name); // Display list name
            }
            return const Text('Shopping List'); // Default or loading title
          },
        ),
        actions: [
          BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
            builder: (context, state) {
              bool showCompleted = false;
              if (state is ShoppingItemLoaded) {
                showCompleted = state.showCompletedItems;
              }
              return IconButton(
                icon: Icon(showCompleted ? Icons.check_circle : Icons.check_circle_outline),
                tooltip: showCompleted ? 'Hide Completed' : 'Show Completed',
                onPressed: () {
                  context.read<ShoppingItemCubit>().toggleShowCompletedItems();
                },
              );
            },
          ),
          BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
            builder: (context, state) {
              bool isGrouped = false;
              if (state is ShoppingItemLoaded) {
                isGrouped = state.groupByCategory;
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'uncheck_all') {
                    context.read<ShoppingItemCubit>().uncheckAllItems();
                  } else if (value == 'toggle_group_by_category') {
                    context.read<ShoppingItemCubit>().toggleGroupByCategory();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'uncheck_all',
                    child: Text('Uncheck All Items'),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle_group_by_category',
                    child: Text(isGrouped ? 'Ungroup by Category' : 'Group by Category'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
        builder: (context, state) {
          if (state is ShoppingItemLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ShoppingItemLoaded) {
            return const ShoppingItemListView();
          } else if (state is ShoppingItemError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Loading items...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddEditShoppingItemDialog(
              shoppingItemCubit: context.read<ShoppingItemCubit>(), // Pass the cubit
            ),
          );
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
