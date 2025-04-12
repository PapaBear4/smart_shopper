import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/models.dart'; // Models barrel file
import '../../../service_locator.dart'; // GetIt for dependency injection
import '../cubit/store_cubit.dart'; // The Cubit for this feature

class StoreManagementScreen extends StatelessWidget {
  const StoreManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit using the factory registered in GetIt
    return BlocProvider(
      create: (context) => getIt<StoreCubit>(),
      child: StoreView(), // Use a separate widget for easy context access
    );
  }
}

class StoreView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Stores'),
        // Consider adding a back button if this isn't the root screen
      ),
      body: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          // --- Loading State ---
          if (state is StoreLoading || state is StoreInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Error State ---
          if (state is StoreError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.message}'),
              ),
            );
          }
          // --- Loaded State ---
          if (state is StoreLoaded) {
            if (state.stores.isEmpty) {
              return const Center(
                  child: Text('No stores saved yet.\nAdd one below!'));
            }
            // Display stores
            return ListView.builder(
              itemCount: state.stores.length,
              itemBuilder: (context, index) {
                final store = state.stores[index];
                return Dismissible(
                  key: ValueKey(store.id),
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
                              content: Text('Delete "${store.name}"?'),
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
                    context.read<StoreCubit>().deleteStore(store.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                          content: Text('${store.name} deleted'),
                          duration: const Duration(seconds: 2)));
                  },
                  child: ListTile(
                    title: Text(store.name),
                    subtitle: Text(
                      // Display address or phone if available
                      store.address?.isNotEmpty == true ? store.address! : (store.phoneNumber?.isNotEmpty == true ? store.phoneNumber! : 'No details'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     trailing: IconButton(
                       icon: const Icon(Icons.edit, size: 20),
                       tooltip: 'Edit Store',
                       onPressed: () {
                          _showAddEditStoreDialog(context, store: store);
                       },
                     ),
                    // Optional: onTap could show full details or launch map later
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
          _showAddEditStoreDialog(context); // Call to add new store
        },
        tooltip: 'Add Store',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Helper Function for Add/Edit Store Dialog ---
  Future<void> _showAddEditStoreDialog(BuildContext context, {GroceryStore? store}) async {
    // Get the cubit instance from the context where the function is called
    final cubit = context.read<StoreCubit>();
    final bool isEditing = store != null;

    // Form key and controllers
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: store?.name ?? '');
    final addressController = TextEditingController(text: store?.address ?? '');
    final websiteController = TextEditingController(text: store?.website ?? '');
    final phoneController = TextEditingController(text: store?.phoneNumber ?? '');

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Store' : 'Add New Store'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Store Name*'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    // No validation needed for optional fields
                  ),
                  TextFormField(
                    controller: websiteController,
                    decoration: const InputDecoration(labelText: 'Website'),
                    keyboardType: TextInputType.url,
                  ),
                   TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
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
                if (formKey.currentState!.validate()) { // Only validates required fields (Name)
                  final name = nameController.text.trim();
                  final address = addressController.text.trim();
                  final website = websiteController.text.trim();
                  final phone = phoneController.text.trim();

                  if (isEditing) {
                     // Create updated store object, preserving the ID
                     final updatedStore = GroceryStore(
                        id: store!.id, // Keep original ID
                        name: name,
                        address: address.isNotEmpty ? address : null, // Store null if empty
                        website: website.isNotEmpty ? website : null,
                        phoneNumber: phone.isNotEmpty ? phone : null,
                     );
                     cubit.updateStore(updatedStore);
                  } else {
                    cubit.addStore(
                      name: name,
                      address: address.isNotEmpty ? address : null,
                      website: website.isNotEmpty ? website : null,
                      phone: phone.isNotEmpty ? phone : null,
                    );
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