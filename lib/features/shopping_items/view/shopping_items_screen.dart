import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart'; // Needed for Cubit creation
import '../../../service_locator.dart'; // Needed for GetIt
import '../cubit/shopping_item_cubit.dart'; // The Cubit for this feature

class ShoppingItemsScreen extends StatelessWidget {
  final int listId; // Received from the router

  const ShoppingItemsScreen({
    super.key,
    required this.listId,
  });

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit. We create it manually here, passing the listId
    // and fetching the repository from GetIt.
    return BlocProvider(
      create: (context) => ShoppingItemCubit(
        repository: getIt<IShoppingItemRepository>(), // Get repo from DI
        listId: listId, // Pass the listId from the route
      ),
      child: ShoppingItemView(), // Use a separate widget for the view content
    );
  }
}

// Separate View widget to easily access the Cubit context below the provider
class ShoppingItemView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use BlocSelector to get the parent list name for the AppBar title.
    // This avoids rebuilding the whole AppBar when only items change.
    final listName = context.select((ShoppingItemCubit cubit) {
      if (cubit.state is ShoppingItemLoaded) {
        return (cubit.state as ShoppingItemLoaded).parentList.name;
      }
      // Return default or loading text if state is not Loaded yet
      return 'Loading...';
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(listName), // Display dynamic list name
      ),
      body: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
        builder: (context, state) {
          // --- Loading State ---
          if (state is ShoppingItemLoading || state is ShoppingItemInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Error State ---
          if (state is ShoppingItemError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.message}'),
              ),
            );
          }
          // --- Loaded State ---
          if (state is ShoppingItemLoaded) {
            if (state.items.isEmpty) {
              return const Center(
                  child: Text('No items in this list yet.\nAdd one below!'));
            }
            // Display items
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                     return await showDialog<bool>(
                           context: context, // Context from builder is fine here
                           builder: (BuildContext ctx) {
                             return AlertDialog(
                               title: const Text('Confirm Deletion'),
                               content: Text('Delete "${item.name}"?'),
                               actions: <Widget>[
                                 TextButton(
                                   onPressed: () => Navigator.of(ctx).pop(false),
                                   child: const Text('Cancel'),
                                 ),
                                 TextButton(
                                   onPressed: () => Navigator.of(ctx).pop(true),
                                   child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                 ),
                               ],
                             );
                           },
                         ) ?? false;
                  },
                  onDismissed: (direction) {
                    context.read<ShoppingItemCubit>().deleteItem(item.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar() // Hide previous snackbar if any
                      ..showSnackBar(SnackBar(
                          content: Text('${item.name} deleted'),
                          duration: const Duration(seconds: 2)));
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (bool? value) {
                        context.read<ShoppingItemCubit>().toggleItemCompletion(item);
                      },
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text('${item.quantity} ${item.unit} (${item.category})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit Item',
                      onPressed: () {
                         _showAddEditItemDialog(context, item: item);
                      },
                    ),
                    // Optional: onTap to view more details later?
                  ),
                );
              },
            );
          }
          // --- Fallback ---
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           _showAddEditItemDialog(context); // Call to add new item
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Helper Function for Add/Edit Item Dialog ---
  Future<void> _showAddEditItemDialog(BuildContext context, {ShoppingItem? item}) async {
    // Get the cubit instance from the context where the function is called
    final cubit = context.read<ShoppingItemCubit>();
    final bool isEditing = item != null;

    // Form key and controllers
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '1');
    final unitController = TextEditingController(text: item?.unit ?? '');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // No need for BlocProvider.value if we pass the cubit instance directly
        return AlertDialog(
          title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevent dialog stretching
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g., Milk'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  Row( // Quantity and Unit side-by-side
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Expanded(
                        flex: 2, // Give quantity less space
                        child: TextFormField(
                          controller: quantityController,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter quantity';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                         flex: 3, // Give unit more space
                        child: TextFormField(
                          controller: unitController,
                          decoration: const InputDecoration(labelText: 'Unit', hintText: 'e.g., gallon, box, lbs'),
                           validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a unit' : null,
                        ),
                      ),
                    ],
                  ),
                   TextFormField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g., Dairy, Produce'),
                       validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter category' : null,
                    ),
                  // TODO: Add Store selection later
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final category = categoryController.text.trim();
                  final quantity = double.parse(quantityController.text); // Already validated
                  final unit = unitController.text.trim();

                  if (isEditing) {
                     // Create updated item, preserving ID and relations
                     final updatedItem = ShoppingItem(
                        id: item.id,
                        name: name,
                        category: category,
                        quantity: quantity,
                        unit: unit,
                        isCompleted: item.isCompleted // Preserve completion status on edit
                     )
                     ..shoppingList.targetId = item.shoppingList.targetId // Preserve ToOne link
                     ..groceryStores.addAll(item.groceryStores); // Preserve ToMany link

                     cubit.updateItem(updatedItem);
                  } else {
                    cubit.addItem(name, category, quantity, unit);
                  }
                  Navigator.of(dialogContext).pop(); // Close dialog
                }
              },
            ),
          ],
        );
      },
    );
  }
}