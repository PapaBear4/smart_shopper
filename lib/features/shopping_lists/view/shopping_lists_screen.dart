import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc package
import '../../../models/models.dart';           // Models barrel file
import '../../../service_locator.dart';         // To get dependencies (GetIt)
import '../cubit/shopping_list_cubit.dart';     // The Cubit for this feature

class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit to the widget tree below.
    // BlocProvider creates and provides an instance of ShoppingListCubit.
    // We use getIt<ShoppingListCubit>() to get the factory-registered instance.
    return BlocProvider(
      create: (context) => getIt<ShoppingListCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Shopping Lists'),
          // Optional: Add actions later if needed
        ),
        // Use BlocBuilder to react to state changes from the Cubit
        body: BlocBuilder<ShoppingListCubit, ShoppingListState>(
          builder: (context, state) {
            // ---- Loading State ----
            if (state is ShoppingListLoading || state is ShoppingListInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            // ---- Error State ----
            if (state is ShoppingListError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading lists: ${state.message}\nPlease try again later.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // ---- Loaded State ----
            if (state is ShoppingListLoaded) {
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
                itemBuilder: (context, index) {
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
                    // Confirmation dialog before deleting (Optional but recommended)
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: Text('Are you sure you want to delete "${list.name}"?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false), // Return false
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true), // Return true
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          ) ?? false; // Return false if dialog is dismissed
                    },
                    onDismissed: (direction) {
                      // Call Cubit method to delete the list
                      context.read<ShoppingListCubit>().deleteList(list.id);
                      // Show a snackbar confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${list.name} deleted'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(list.name),
                      trailing: IconButton( // Edit button
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showAddEditListDialog(context, list: list); // Pass list for editing
                        },
                      ),
                      onTap: () {
                        // TODO: Navigate to list details screen
                        print('Tapped on list: ${list.name} (ID: ${list.id})');
                        // Example for later using go_router:
                        // context.push('/list/${list.id}');
                      },
                    ),
                  );
                },
              );
            }
            // Fallback for any unhandled state (shouldn't happen ideally)
            return const Center(child: Text('Something went wrong.'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddEditListDialog(context); // Call without list for adding
          },
          tooltip: 'Add New List',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // --- Helper Function for Add/Edit Dialog ---
  Future<void> _showAddEditListDialog(BuildContext context, {ShoppingList? list}) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(text: list?.name ?? '');
    final bool isEditing = list != null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        // Use BlocProvider.value to provide the existing Cubit instance to the dialog
        return BlocProvider.value(
          value: BlocProvider.of<ShoppingListCubit>(context),
          child: AlertDialog(
            title: Text(isEditing ? 'Rename List' : 'Add New List'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
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
                  if (_formKey.currentState!.validate()) {
                    final listName = nameController.text.trim();
                    if (isEditing) {
                      // Call rename method from the Cubit provided to the dialog
                      dialogContext.read<ShoppingListCubit>().renameList(list!.id, listName);
                    } else {
                       // Call add method from the Cubit provided to the dialog
                      dialogContext.read<ShoppingListCubit>().addList(listName);
                    }
                    Navigator.of(dialogContext).pop(); // Close the dialog
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}