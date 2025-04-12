// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
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
  const ShoppingItemView({super.key});
  @override
  // WIDGET FOR THE LIST ITSELF
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
      // TOP APPBAR
      appBar: AppBar(
        title: Text(listName), // Display dynamic list name
      ),
      // BODY CONTENT
      body: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
        builder: (context, state) {
          // --- LOADING State ---
          if (state is ShoppingItemLoading || state is ShoppingItemInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- ERROR State ---
          if (state is ShoppingItemError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.message}'),
              ),
            );
          }
          // --- LOADED State ---
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
                          context: context,
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
                  // EACH ITEM
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
          // --- FALL BACK ---
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      // FLOATING ACTION BUTTON to add new item
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditItemDialog(context); // Call to add new item
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- ADD/EDIT ITEM DIALOG ---
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

    // Changed from Set<int> to int? for single store selection
    int? selectedStoreId =
        isEditing && item.groceryStores.isNotEmpty
            ? item
                .groceryStores
                .first
                .id // Get the first store if editing
            : null;

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

    // THE DIALOG ITSELF
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

            // DIALOG CONTENTS
            return AlertDialog(
              title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
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
                      const SizedBox(height: 8),
                      // --- Quantity and Unit Fields ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 2,
                            // --- Quantity ---
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
                                if (value == null || value.isEmpty) {
                                  return 'Enter quantity';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                if (double.parse(value) <= 0) {
                                  return 'Must be > 0'; // Optional: Ensure positive
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // --- Unit ---
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
                      const SizedBox(height: 8),
                      // --- CATEGORY Field ---
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
                      const Divider(height: 30, thickness: 1),

                      // --- Store Selection Section ---
                      const Text(
                        'Store to purchase at:',
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
                            : DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Store',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedStoreId,
                              hint: const Text('Select a store'),
                              isExpanded: true,
                              items:
                                  allStores!.map((store) {
                                    return DropdownMenuItem<int>(
                                      value: store.id,
                                      child: Text(store.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                stfSetState(() {
                                  selectedStoreId = value;
                                });
                              },
                            ),
                      // --- End Store Selection ---
                    ],
                  ),
                ), // End Form
              ),
              // ---BOTTOM ACTIONS ---
              actions: <Widget>[
                // --- CANCEL ---
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                // --- SAVE ---
                TextButton(
                  child: Text(isEditing ? 'Save' : 'Add'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final category = categoryController.text.trim();
                      final quantity = double.parse(quantityController.text);
                      final unit = unitController.text.trim();

                      // Find the single store (if selected)
                      GroceryStore? selectedStore; // Initialize as null
                      if (selectedStoreId != null && allStores != null) {
                        try {
                          // firstWhere without orElse throws if not found
                          selectedStore = allStores?.firstWhere(
                            (store) => store.id == selectedStoreId,
                          );
                        } on StateError {
                          // Catch the error when no element satisfies the test
                          selectedStore = null;
                        }
                      }

                      if (isEditing) {
                        // Update existing item
                        final updatedItem =
                            item; // We know item is not null if isEditing
                        // Update scalar fields
                        updatedItem.name = name;
                        updatedItem.category = category;
                        updatedItem.quantity = quantity;
                        updatedItem.unit = unit;

                        // Update store relation
                        updatedItem.groceryStores
                            .clear(); // Clear existing links
                        if (selectedStore != null) {
                          updatedItem.groceryStores.add(
                            selectedStore,
                          ); // Add single selected store
                        }
                        // UPDATE EXISTING ITEM VIA CUBIT
                        cubit.updateItem(updatedItem);
                      } else {
                        // CREATE new item
                        final newItem = ShoppingItem(
                          name: name,
                          category: category,
                          quantity: quantity,
                          unit: unit,
                          isCompleted: false,
                        );

                        // Set single store if selected
                        if (selectedStore != null) {
                          newItem.groceryStores.add(selectedStore);
                        }

                        // Add the item via cubit
                        cubit.addItem(newItem);
                      }

                      Navigator.of(dialogContext).pop(); // Close dialog
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
