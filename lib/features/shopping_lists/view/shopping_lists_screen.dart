import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../service_locator.dart'; 
import '../cubit/shopping_list_cubit.dart';
import '../../../features/scan_list/presentation/pages/scan_list_page.dart'; // Added for Scan List Page
import 'dart:developer';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

/// Top-level screen for displaying and managing shopping lists
/// Follows the screen-level BlocProvider pattern where each screen is responsible for
/// creating and managing its own state
class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // PATTERN: Screen-level BlocProvider
    // Create a ShoppingListCubit when this screen is first built
    // This pattern keeps state management close to the UI that needs it
    return BlocProvider(
      // Create the context with the ShoppingListCubit instance (factory pattern)
      create: (context) => getIt<ShoppingListCubit>(),
      // We separate the UI into a distinct widget to access the BlocProvider's context
      child: const ShoppingListsView(),
    );
  }
}

/// Separate view widget that handles UI rendering based on Bloc state
/// This separation provides cleaner access to the BlocProvider context
class ShoppingListsView extends StatelessWidget {
  const ShoppingListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === APPBAR: Top navigation bar ===
      appBar: AppBar(
        title: const Text('My Shopping Lists'),
        // Store management button in the app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Manage Stores',
            onPressed: () {
              // Navigation using GoRouter - pushes the stores screen onto the navigation stack
              context.push('/stores');
            },
          ),
          // TODO: Hide debug features in release mode before final deployment
          // if (kDebugMode) // Only show debug button in debug mode
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Open Debug Menu',
            onPressed: () {
              context.push('/debug');
            },
          ),
        ],
      ),
      
      // === BODY: Main content area ===
      // BlocBuilder automatically rebuilds UI when the cubit emits a new state
      body: BlocBuilder<ShoppingListCubit, ShoppingListState>(
        builder: (context, state) {
          // --- LOADING STATE ---
          // Display a loading indicator while data is being fetched
          if (state is ShoppingListLoading || state is ShoppingListInitial) {
            log('State: Loading or Initial', name: 'ShoppingListsScreen');
            return const Center(child: CircularProgressIndicator());
          }
          
          // --- LOADED STATE ---
          // Display shopping lists or an empty state message
          else if (state is ShoppingListLoaded) {
            log('State: Loaded with ${state.lists.length} lists', name: 'ShoppingListsScreen');
            
            // EMPTY STATE - Show message when no lists exist yet
            if (state.lists.isEmpty) {
              return const Center(
                child: Text(
                  'No shopping lists yet!\nTap the + button to add one.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            // LIST VIEW - Display all shopping lists in a scrollable list
            return ListView.builder(
              itemCount: state.lists.length,
              itemBuilder: (listContext, index) {
                final list = state.lists[index];
                
                // DISMISSIBLE - Enable swipe-to-delete functionality
                return Dismissible(
                  key: ValueKey(list.id), // Unique key for each list
                  direction: DismissDirection.endToStart, // Right-to-left swipe only
                  // Red background with delete icon visible during swipe
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  
                  // CONFIRMATION DIALOG - Prevents accidental deletion
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text(
                                'Are you sure you want to delete "${list.name}"?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    dialogContext,
                                  ).pop(false), // Cancel delete
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    dialogContext,
                                  ).pop(true), // Confirm delete
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false; // Default to false if dialog is dismissed
                  },
                  
                  // DELETE ACTION - Execute after confirmation
                  onDismissed: (direction) {
                    // Tell the cubit to delete this list from the repository
                    context.read<ShoppingListCubit>().deleteList(
                          list.id,
                        );
                    // Show feedback to the user with a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${list.name} deleted'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  
                  // LIST TILE - The actual list item UI
                  child: ListTile(
                    title: Text(list.name),
                    // Edit button
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Show dialog to edit this list's name
                        _showAddEditListDialog(context, list: list);
                      },
                    ),
                    // Navigate to list details when tapped
                    onTap: () {
                      // GoRouter navigation to the items screen with the list ID as parameter
                      context.push('/list/${list.id}');
                    },
                  ),
                );
              },
            );
          }
          
          // --- ERROR STATE ---
          // Display error message if something went wrong
          else if (state is ShoppingListError) {
            log('State: Error - ${state.message}', name: 'ShoppingListsScreen', error: state.message);
            return Center(child: Text('Error loading lists: ${state.message}'));
          }
          
          // --- FALLBACK STATE ---
          // Default case for any unhandled state (should rarely happen)
          log('State: Unknown - $state', name: 'ShoppingListsScreen');
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      
      // === FLOATING ACTION BUTTON ===
      // Button to add a new shopping list
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              // Show dialog to create a new shopping list
              _showAddEditListDialog(context);
            },
            tooltip: 'Add New List',
            heroTag: 'addListFab', // Added heroTag
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              context.push(ScanListPage.routeName); // Navigate to Scan List Page
            },
            tooltip: 'Scan New List',
            heroTag: 'scanListFab', // Added heroTag
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog for adding a new shopping list or editing an existing one
  /// If [list] parameter is provided, the dialog operates in edit mode
  /// Otherwise, it's in create mode
  Future<void> _showAddEditListDialog(
    BuildContext context, {
    ShoppingList? list,
  }) async {
    // Get cubit reference for data operations
    final cubit = context.read<ShoppingListCubit>();

    // Setup form validation
    final formKey = GlobalKey<FormState>();
    
    // Controller to manage the text field value
    final TextEditingController nameController = TextEditingController(
      text: list?.name ?? '', // Pre-fill with list name if editing
    );
    
    // Determine if we're editing or creating
    final bool isEditing = list != null;

    // Show the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Modal dialog (can't dismiss by tapping outside)
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Rename List' : 'Add New List'),
          // DIALOG CONTENT - Form with name field
          content: SingleChildScrollView(
            child: Form(
              key: formKey, // Used for validation
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true, // Focus this field when dialog opens
                    decoration: const InputDecoration(hintText: 'List Name'),
                    // VALIDATION - Ensure name isn't empty
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a list name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          // DIALOG ACTIONS - Cancel or Save/Add
          actions: <Widget>[
            // Cancel button - dismiss dialog without saving
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            // Save/Add button - process form if valid
            TextButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              onPressed: () {
                // Validate the form first
                if (formKey.currentState!.validate()) {
                  final listName = nameController.text.trim();
                  
                  if (isEditing) {
                    // EDIT MODE - Update existing list name
                    cubit.renameList(list.id, listName);
                  } else {
                    // CREATE MODE - Add new list
                    cubit.addList(listName);
                  }
                  
                  // Close the dialog
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}