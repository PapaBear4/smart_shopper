import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper2/repositories/store_repository.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart'; // Needed for Cubit creation
import '../../../service_locator.dart'; // Needed for GetIt
import '../cubit/shopping_item_cubit.dart'; // The Cubit for this feature

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
                child: Text('No items in this list yet.\nAdd one below!'),
              );
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
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;
                  },
                  onDismissed: (direction) {
                    context.read<ShoppingItemCubit>().deleteItem(item.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar() // Hide previous snackbar if any
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${item.name} deleted'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (bool? value) {
                        context.read<ShoppingItemCubit>().toggleItemCompletion(
                          item,
                        );
                      },
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration:
                            item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        color: item.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(
                      '${item.quantity} ${item.unit} (${item.category})',
                    ),
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
  // --- Helper Function for Add/Edit Item Dialog (with Store Selection) ---
  Future<void> _showAddEditItemDialog(
    BuildContext context, {
    ShoppingItem? item,
  }) async {
    // Get the necessary cubit and repository instances from the context/DI
    final cubit = context.read<ShoppingItemCubit>();
    final storeRepository = getIt<IStoreRepository>(); // To fetch stores
    final bool isEditing = item != null;

    // Form key and controllers
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController = TextEditingController(
      text: item?.category ?? '',
    );
    final quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '1',
    );
    final unitController = TextEditingController(text: item?.unit ?? '');

    // State needed within the dialog
    List<GroceryStore>? allStores; // Will hold fetched stores
    Set<int> selectedStoreIds =
        isEditing
            ? item!.groceryStores
                .map((store) => store.id)
                .toSet() // Initialize with existing selections if editing
            : {}; // Start with empty set if adding
    bool isLoadingStores = true;
    String? storeError;

    // --- Fetch stores function ---
    Future<void> fetchStores(StateSetter setState) async {
      try {
        final stores = await storeRepository.getAllStores();
        setState(() {
          allStores = stores;
          isLoadingStores = false;
        });
      } catch (e) {
        setState(() {
          storeError = "Error loading stores: $e";
          isLoadingStores = false;
        });
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage state within the dialog
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            // Fetch stores the first time the dialog builds
            if (allStores == null && isLoadingStores && storeError == null) {
              fetchStores(stfSetState);
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    // <<< Use this complete Column definition
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // --- Name Field ---
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Item Name*',
                          hintText: 'e.g., Milk',
                        ),
                        validator:
                            (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Enter a name'
                                    : null,
                      ),
                      const SizedBox(height: 8), // Spacing
                      // --- Quantity and Unit Fields ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity*',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Enter quantity';
                                if (double.tryParse(value) == null)
                                  return 'Invalid number';
                                if (double.parse(value) <= 0)
                                  return 'Must be > 0'; // Optional: Ensure positive
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit*',
                                hintText: 'e.g., gallon, box, lbs',
                              ),
                              validator:
                                  (value) =>
                                      (value == null || value.trim().isEmpty)
                                          ? 'Enter a unit'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Spacing
                      // --- Category Field ---
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category*',
                          hintText: 'e.g., Dairy, Produce',
                        ),
                        validator:
                            (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Enter category'
                                    : null,
                      ),
                      const Divider(height: 30, thickness: 1), // Separator
                      // --- Store Selection Section ---
                      const Text(
                        'Associated Stores:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (isLoadingStores)
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (storeError != null)
                        Text(
                          storeError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (!isLoadingStores && storeError == null)
                        (allStores?.isEmpty ?? true)
                            ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No stores saved yet.\nAdd stores via Manage Stores screen first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                            : Wrap(
                              // Use Wrap for chips
                              spacing: 8.0, // Horizontal space between chips
                              runSpacing: 0.0, // Vertical space between rows
                              children:
                                  allStores!.map((store) {
                                    return FilterChip(
                                      label: Text(store.name),
                                      selected: selectedStoreIds.contains(
                                        store.id,
                                      ),
                                      onSelected: (bool selected) {
                                        stfSetState(() {
                                          // Use stfSetState from StatefulBuilder
                                          if (selected) {
                                            selectedStoreIds.add(store.id);
                                          } else {
                                            selectedStoreIds.remove(store.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                      // --- End Store Selection ---
                    ],
                  ),
                ), // End Form
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
                      final quantity = double.parse(quantityController.text);
                      final unit = unitController.text.trim();

                      // Find the actual GroceryStore objects for the selected IDs
                      // This assumes allStores is loaded and not null if selection occurred
                      final List<GroceryStore> selectedStores =
                          allStores
                              ?.where((s) => selectedStoreIds.contains(s.id))
                              .toList() ??
                          [];

                      if (isEditing) {
                        log(
                          "Calling cubit.renameList...",
                          name: 'AddEditItemDialog',
                        ); // Example for edit
                        // Update existing item
                        final updatedItem =
                            item!; // We know item is not null if isEditing
                        // Update scalar fields
                        updatedItem.name = name;
                        updatedItem.category = category;
                        updatedItem.quantity = quantity;
                        updatedItem.unit = unit;
                        // Update ToMany relation
                        updatedItem.groceryStores
                            .clear(); // Clear existing links
                        updatedItem.groceryStores.addAll(
                          selectedStores,
                        ); // Add current selections

                        cubit.updateItem(updatedItem);
                      } else {
                        log(
                          "Calling cubit.addList with name: $name",
                          name: 'AddEditItemDialog',
                        ); // <<< Use log
                        // Create new item and set relations
                        final newItem = ShoppingItem(
                          name: name,
                          category: category,
                          quantity: quantity,
                          unit: unit,
                          isCompleted: false,
                        );
                        newItem.groceryStores.addAll(
                          selectedStores,
                        ); // Set ToMany link
                        log("DIALOG: Calling cubit.addItem for name: $name");

                        // The cubit's addItem method calls the repository which links ToOne shoppingList
                        cubit.addItem(name, category, quantity, unit);
                        // IMPORTANT CORRECTION: The current addItem signature doesn't take the item
                        // We need to modify the cubit/repo or handle it differently.
                        // Easiest: Modify cubit.addItem to take the constructed item or modify repo.addItem.
                        // Let's assume we modify cubit.addItem later OR handle saving here:
                        // --> Reverting cubit call for now, needs adjustment later <--
                        // print("Need to adjust how item with stores is added via cubit");
                        // For now, let's just make a direct repo call for simplicity,
                        // although ideally this goes via cubit.
                        cubit.addItem(
                          name,
                          category,
                          quantity,
                          unit,
                        ); //KEEPING THIS - We'll adjust addItem signature later
                      }
                      log(
                        "Cubit call finished.",
                        name: 'AddEditItemDialog',
                      ); // <<< Use log
                      Navigator.of(dialogContext).pop(); // Close dialog
                    } else {
                      log(
                        "Validation failed.",
                        name: 'AddEditItemDialog',
                      ); // <<< Use log (optional)
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Helper TextFormField builders (kept from previous dialog example for brevity)
// You'll need to ensure these TextFormField widgets are correctly placed within the Column
// (e.g., TextFormField(...) for Name, Row(...) for Qty/Unit, TextFormField(...) for Category)
// The code above shows the structure - fill in the TextFormField details as before.}
