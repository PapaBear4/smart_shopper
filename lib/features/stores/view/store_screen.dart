import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart'; // Models barrel file
import '../../../service_locator.dart'; // GetIt for dependency injection
import '../cubit/store_cubit.dart'; // The Cubit for this feature

/// Screen for managing grocery stores (add, edit, delete store information)
/// This screen follows our screen-level BlocProvider pattern where each screen
/// creates and manages its own state via BlocProvider
class StoreManagementScreen extends StatelessWidget {
  const StoreManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // PATTERN: Screen-level BlocProvider
    // Create a new StoreCubit instance when this screen is built
    // This ensures state is fresh and isn't shared with other screens
    return BlocProvider(
      // Get StoreCubit instance from the dependency injection system
      create: (context) => getIt<StoreCubit>(),
      // Child widget that will access this Cubit via context
      child: const StoreView(), // Separating view logic into a distinct widget
    );
  }
}

/// Separate view widget that handles UI rendering based on Bloc state
/// This separation provides cleaner access to the BlocProvider context
class StoreView extends StatelessWidget {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Stores'),
        // No explicit back button needed - Go Router handles navigation
      ),
      // BlocBuilder rebuilds the UI whenever the StoreCubit emits a new state
      body: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          // --- LOADING STATE ---
          // Show loading indicator while initial data is being fetched
          if (state is StoreLoading || state is StoreInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // --- ERROR STATE ---
          // Display error message if something went wrong
          if (state is StoreError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.message}'),
              ),
            );
          }
          
          // --- LOADED STATE ---
          // Shows the list of stores or an empty state message
          if (state is StoreLoaded) {
            // Empty state message if no stores exist yet
            if (state.stores.isEmpty) {
              return const Center(
                  child: Text('No stores saved yet.\nAdd one below!'));
            }
            
            // Display list of stores using ListView.builder for efficient rendering
            return ListView.builder(
              itemCount: state.stores.length,
              itemBuilder: (context, index) {
                final store = state.stores[index];
                
                // Dismissible allows swipe-to-delete functionality
                return Dismissible(
                  key: ValueKey(store.id), // Unique key for each store
                  direction: DismissDirection.endToStart, // Right-to-left swipe only
                  // Red background with delete icon when swiping
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  // Confirmation dialog to prevent accidental deletion
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext ctx) {
                            return AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Delete "${store.name}"?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false), // Cancel delete
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true), // Confirm delete
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        ) ?? false; // Default to false if dialog is dismissed
                  },
                  // Execute when item is actually dismissed (after confirmation)
                  onDismissed: (direction) {
                    // Call the cubit method to delete the store in the repository
                    context.read<StoreCubit>().deleteStore(store.id);
                    // Show feedback to user via snackbar
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar() // Hide any existing snackbar first
                      ..showSnackBar(SnackBar(
                          content: Text('${store.name} deleted'),
                          duration: const Duration(seconds: 2)));
                  },
                  // The actual list tile showing store information
                  child: ListTile(
                    title: Text(store.name),
                    // Show address or phone number as subtitle if available
                    subtitle: Text(
                      // Conditional display based on data availability
                      store.address?.isNotEmpty == true ? store.address! : (store.phoneNumber?.isNotEmpty == true ? store.phoneNumber! : 'No details'),
                      maxLines: 1, // Prevent multi-line display
                      overflow: TextOverflow.ellipsis, // Handle long text gracefully
                    ),
                    trailing: IconButton( // Keep only the edit button in trailing
                       icon: const Icon(Icons.edit, size: 20),
                       tooltip: 'Edit Store',
                       onPressed: () {
                          // Show dialog to edit this store's details
                          _showAddEditStoreDialog(context, store: store);
                       },
                     ),
                    onTap: () { // Add onTap to the ListTile itself
                      // Navigate to the new screen using GoRouter
                      GoRouter.of(context).push('/stores/${store.id}/items');
                    },
                  ),
                );
              },
            );
          }
          
          // --- FALLBACK STATE ---
          // Should never reach here if all states are properly handled
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      // FAB for adding new stores
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditStoreDialog(context); // Show dialog to add a new store
        },
        tooltip: 'Add Store',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows a dialog for adding a new store or editing an existing one
  /// If [store] parameter is provided, dialog is in edit mode
  /// Otherwise, dialog is in add mode
  Future<void> _showAddEditStoreDialog(BuildContext context, {GroceryStore? store}) async {
    // Get cubit reference for data operations
    final cubit = context.read<StoreCubit>();
    final bool isEditing = store != null;

    // Form setup for validation
    final formKey = GlobalKey<FormState>();
    
    // Controllers to manage form field values
    final nameController = TextEditingController(text: store?.name ?? '');
    final addressController = TextEditingController(text: store?.address ?? '');
    final websiteController = TextEditingController(text: store?.website ?? '');
    final phoneController = TextEditingController(text: store?.phoneNumber ?? '');

    // Show dialog with form fields
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Modal dialog (can't dismiss by tapping outside)
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Store' : 'Add New Store'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey, // Form key used for validation
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make dialog compact
                children: <Widget>[
                  // Store name field (required)
                  TextFormField(
                    controller: nameController,
                    autofocus: true, // Focus this field when dialog opens
                    decoration: const InputDecoration(labelText: 'Store Name*'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  // Address field (optional)
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    // No validation for optional fields
                  ),
                  // Website field (optional)
                  TextFormField(
                    controller: websiteController,
                    decoration: const InputDecoration(labelText: 'Website'),
                    keyboardType: TextInputType.url, // Shows URL-optimized keyboard on mobile
                  ),
                  // Phone number field (optional)
                   TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone, // Shows phone-optimized keyboard on mobile
                  ),
                ],
              ),
            ),
          ),
          // Dialog action buttons
          actions: <Widget>[
            // Cancel button - closes dialog without saving
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            // Save/Add button - processes form data if valid
            TextButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              onPressed: () {
                // Only proceed if all required fields are valid
                if (formKey.currentState!.validate()) {
                  // Extract and trim all field values
                  final name = nameController.text.trim();
                  final address = addressController.text.trim();
                  final website = websiteController.text.trim();
                  final phone = phoneController.text.trim();

                  if (isEditing) {
                     // EDIT MODE: Update existing store, preserving the ID
                     final updatedStore = GroceryStore(
                        id: store.id, // Keep original ID
                        name: name,
                        address: address.isNotEmpty ? address : null, // Use null for empty optional fields
                        website: website.isNotEmpty ? website : null,
                        phoneNumber: phone.isNotEmpty ? phone : null,
                     );
                     // Call cubit to update the store in repository
                     cubit.updateStore(updatedStore);
                  } else {
                    // ADD MODE: Create a new store
                    cubit.addStore(
                      name: name,
                      address: address.isNotEmpty ? address : null,
                      website: website.isNotEmpty ? website : null,
                      phone: phone.isNotEmpty ? phone : null,
                    );
                  }
                  Navigator.of(dialogContext).pop(); // Close dialog after save/add
                }
              },
            ),
          ],
        );
      },
    );
  }
}