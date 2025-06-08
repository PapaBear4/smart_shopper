// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/repositories/store_repository.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_item_repository.dart'; // Needed for Cubit creation
import '../../../service_locator.dart'; // Needed for GetIt
import '../cubit/shopping_item_cubit.dart'; // The Cubit for this feature
import '../../../repositories/brand_repository.dart'; // Added for Brand selection
import '../../../repositories/price_entry_repository.dart'; // Added for PriceEntry
import 'package:intl/intl.dart'; // For date formatting
import 'package:collection/collection.dart'; // Added for firstWhereOrNull

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
    final brandRepository = getIt<IBrandRepository>(); // To fetch brands
    final priceEntryRepository = getIt<IPriceEntryRepository>(); // To add price entries
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
    final newBrandNameController = TextEditingController();
    final priceController = TextEditingController();

    // State needed within the dialog
    List<GroceryStore>? allStores; // Will hold fetched stores
    int? selectedStoreId =
        isEditing && item.groceryStores.isNotEmpty // Corrected: item is non-null if isEditing is true
            ? item.groceryStores.first.id
            : null;
    bool isLoadingStores = true;
    String? storeError;

    List<Brand>? allBrands;
    int? selectedBrandId = item?.brand.targetId;
    bool isLoadingBrands = true;
    String? brandError;
    bool showNewBrandField = false;

    DateTime? selectedDate = DateTime.now(); // Default to today for PriceEntry

    // --- Fetch stores function ---
    Future<void> fetchStores(StateSetter setState) async {
      try {
        // Ensure storeRepository is initialized
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

    // --- Fetch brands function ---
    Future<void> fetchBrands(StateSetter setState) async {
      try {
        // Ensure brandRepository is initialized
        final brands = await brandRepository.getAllBrands();
        setState(() {
          allBrands = brands;
          isLoadingBrands = false;
        });
      } catch (e) {
        setState(() {
          brandError = "Error loading brands: $e";
          isLoadingBrands = false;
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
            // Fetch brands the first time
            if (allBrands == null && isLoadingBrands && brandError == null) {
              fetchBrands(stfSetState);
            }

            // DIALOG CONTENTS
            return AlertDialog(
              title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        (allStores == null || allStores!.isEmpty)
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No stores saved yet.\\nAdd stores via Manage Stores screen first.',
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
                                items: allStores!.map((store) {
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
                      const Divider(height: 30, thickness: 1),

                      // --- Brand Selection Section ---
                      const Text(
                        'Brand:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (isLoadingBrands)
                        const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      if (brandError != null)
                        Text(brandError!, style: const TextStyle(color: Colors.red)),
                      if (!isLoadingBrands && brandError == null && !showNewBrandField)
                        Row(
                          children: [
                            Expanded(
                              child: (allBrands == null || allBrands!.isEmpty)
                                  ? const Text(
                                      'No brands saved yet. Add one below.',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey),
                                    )
                                  : DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(
                                        labelText: 'Select Brand',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: selectedBrandId,
                                      hint: const Text('Select a brand (optional)'),
                                      isExpanded: true,
                                      items: allBrands!.map((brand) {
                                        return DropdownMenuItem<int>(
                                          value: brand.id,
                                          child: Text(brand.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        stfSetState(() {
                                          selectedBrandId = value;
                                        });
                                      },
                                    ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Add New Brand',
                              onPressed: () {
                                stfSetState(() {
                                  showNewBrandField = true;
                                });
                              },
                            ),
                          ],
                        ),
                      if (showNewBrandField)
                        TextFormField(
                          controller: newBrandNameController,
                          decoration: InputDecoration(
                            labelText: 'New Brand Name',
                            hintText: 'Enter brand if not listed',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              tooltip: 'Cancel New Brand',
                              onPressed: () {
                                stfSetState(() {
                                  showNewBrandField = false;
                                  newBrandNameController.clear();
                                });
                              },
                            )
                          ),
                          validator: (value) {
                            // Only validate if new brand field is shown and no existing brand selected
                            if (showNewBrandField && selectedBrandId == null && (value == null || value.trim().isEmpty)) {
                              // return 'Enter new brand name or select existing';
                            }
                            return null;
                          },
                        ),
                      const Divider(height: 30, thickness: 1),

                      // --- Price Entry Section ---
                      const Text(
                        'Log Price:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: 'e.g., 2.99',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Invalid price';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Price must be positive';
                            }
                          }
                          return null; // Price is optional
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Date: Not set'
                                  : 'Date: ${DateFormat.yMd().format(selectedDate!)}', // Corrected: Ensure intl is imported and available
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Select Date'),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: stfContext, // use stfContext for dialogs from StatefulBuilder
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (picked != null && picked != selectedDate) {
                                stfSetState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
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
                  onPressed: () async { // Made async for repository calls
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final category = categoryController.text.trim();
                      final quantity = double.parse(quantityController.text);
                      final unit = unitController.text.trim();

                      int? finalBrandId = selectedBrandId;
                      if (showNewBrandField && newBrandNameController.text.isNotEmpty) {
                        try {
                          final newBrand = Brand(name: newBrandNameController.text.trim());
                          finalBrandId = await brandRepository.addBrand(newBrand);
                        } catch (e) {
                          // Handle error adding brand, maybe show a snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error adding new brand: $e"))
                          );
                          return; // Don't proceed if brand creation fails
                        }
                      }

                      ShoppingItem shoppingItemToSave;
                      if (isEditing) {
                        shoppingItemToSave = item; // item is not null here due to isEditing check
                        shoppingItemToSave.name = name;
                        shoppingItemToSave.category = category;
                        shoppingItemToSave.quantity = quantity;
                        shoppingItemToSave.unit = unit;
                      } else {
                        shoppingItemToSave = ShoppingItem(
                          name: name,
                          category: category,
                          quantity: quantity,
                          unit: unit,
                          isCompleted: false,
                        );
                      }

                      // Link brand
                      if (finalBrandId != null) {
                        shoppingItemToSave.brand.targetId = finalBrandId;
                      } else {
                        shoppingItemToSave.brand.targetId = 0; // Or handle no brand selected
                      }

                      // Link store (single store for now as per existing dialog logic)
                      shoppingItemToSave.groceryStores.clear();
                      if (selectedStoreId != null && allStores != null) {
                        final storeToAdd = allStores!.firstWhereOrNull((s) => s.id == selectedStoreId);
                        if (storeToAdd != null) {
                           shoppingItemToSave.groceryStores.add(storeToAdd);
                        }
                      }

                      if (isEditing) {
                        await cubit.updateItem(shoppingItemToSave);
                      } else {
                        await cubit.addItem(shoppingItemToSave);
                      }

                      // Add Price Entry if price is provided
                      if (priceController.text.isNotEmpty && selectedDate != null) {
                        final price = double.tryParse(priceController.text);
                        if (price != null && price > 0) {
                          final newPriceEntry = PriceEntry(
                            price: price,
                            date: selectedDate!,
                            canonicalItemName: name, // Use the item's name
                          );
                          if (selectedStoreId != null) {
                            newPriceEntry.groceryStore.targetId = selectedStoreId;
                          }
                          if (finalBrandId != null) {
                            newPriceEntry.brand.targetId = finalBrandId;
                          }
                          try {
                            await priceEntryRepository.addPriceEntry(newPriceEntry);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error saving price entry: $e"))
                            );
                          }
                        }
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
