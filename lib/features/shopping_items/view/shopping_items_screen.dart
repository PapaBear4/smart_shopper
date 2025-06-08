// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/features/shopping_items/cubit/shopping_item_cubit.dart';
import 'package:smart_shopper/features/shopping_items/widgets/add_edit_shopping_item_dialog.dart';
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
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Show Completed',
            onPressed: () {
              // TODO: Implement filter for completed items
            },
          ),
        ],
      ),
      body: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
        builder: (context, state) {
          if (state is ShoppingItemLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ShoppingItemLoaded) {
            if (state.items.isEmpty) {
              return const Center(child: Text('No items yet. Add some!'));
            }
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (bool? value) {
                        if (value != null) {
                          // Pass the whole item to the cubit method
                          context.read<ShoppingItemCubit>().toggleItemCompletion(item);
                        }
                      },
                    ),
                    title: Text(item.name, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
                    subtitle: Text('${item.quantity} ${item.unit} - ${item.category}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit Item',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditShoppingItemDialog(item: item),
                        );
                      },
                    ),
                    onTap: () {
                        // TODO: Show item details or quick edit options
                    }
                  ),
                );
              },
            );
          } else if (state is ShoppingItemError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Press + to add an item.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditShoppingItemDialog(),
          );
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
