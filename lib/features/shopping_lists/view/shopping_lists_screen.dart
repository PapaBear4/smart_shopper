import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc package
import 'package:go_router/go_router.dart';
import '../../../models/models.dart'; // Models barrel file
import '../cubit/shopping_list_cubit.dart'; // The Cubit for this feature
import 'dart:developer'; // Import for logging

class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocProvider is now handled by the router.
    // Scaffold is now the top-level widget returned by build.
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.storefront,
            ), // Or Icons.settings, Icons.store
            tooltip: 'Manage Stores',
            onPressed: () {
              // Use context directly to navigate
              context.push('/stores');
            },
          ),
        ],
      ),
      // Use BlocBuilder to react to state changes from the Cubit
      body: BlocBuilder<ShoppingListCubit, ShoppingListState>(
        builder: (context, state) { // Use the context from the build method
          // ---- Loading State ----
          if (state is ShoppingListLoading || state is ShoppingListInitial) {
            log('State: Loading or Initial', name: 'ShoppingListsScreen'); // Example log
            return const Center(child: CircularProgressIndicator());
          }
          // ---- Loaded State ----
          else if (state is ShoppingListLoaded) {
            log('State: Loaded with ${state.lists.length} lists', name: 'ShoppingListsScreen'); // Example log
            // Handle empty list case
            if (state.lists.isEmpty) {
              return const Center(
                child: Text(
                  'No shopping lists yet!\nTap the + button to add one.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            // Display the list using ListView.builder
            return ListView.builder(
              itemCount: state.lists.length,
              itemBuilder: (listContext, index) { // listContext is fine here
                final list = state.lists[index];
                return Dismissible(
                  key: ValueKey(list.id), // Unique key for Dismissible
                  direction: DismissDirection.endToStart, // Swipe left to delete
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  // Confirmation dialog before deleting
                  confirmDismiss: (direction) async {
                    // Use context directly
                    return await showDialog<bool>(
                          context: context, // Use context from build method
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
                                  ).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    dialogContext,
                                  ).pop(true),
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
                    // Use context directly for Cubit interaction
                    context.read<ShoppingListCubit>().deleteList(
                          list.id,
                        );
                    ScaffoldMessenger.of(context).showSnackBar( // Use context
                      SnackBar(
                        content: Text('${list.name} deleted'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(list.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Use context directly for dialog function
                        _showAddEditListDialog(context, list: list);
                      },
                    ),
                    onTap: () {
                      // Use context directly for navigation
                      context.push('/list/${list.id}');
                    },
                  ),
                );
              },
            );
          }
          // ---- Error State ----
          else if (state is ShoppingListError) {
             log('State: Error - ${state.message}', name: 'ShoppingListsScreen', error: state.message); // Example log
             return Center(child: Text('Error loading lists: ${state.message}'));
          }
          // Fallback for any unhandled state
          log('State: Unknown - $state', name: 'ShoppingListsScreen'); // Example log
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Use context directly
          _showAddEditListDialog(context);
        },
        tooltip: 'Add New List',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Helper Function for Add/Edit Dialog ---
  // This function remains the same, it correctly uses the context passed to it.
  Future<void> _showAddEditListDialog(
    BuildContext context, {
    ShoppingList? list,
  }) async {
    // Capture the cubit from the context before showing dialog
    final cubit = context.read<ShoppingListCubit>();

    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: list?.name ?? '',
    );
    final bool isEditing = list != null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Rename List' : 'Add New List'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'List Name'),
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
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final listName = nameController.text.trim();
                  if (isEditing) {
                    // Use the captured cubit
                    cubit.renameList(list.id, listName);
                  } else {
                    // Use the captured cubit
                    cubit.addList(listName);
                  }
                  Navigator.of(dialogContext).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }
}