import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../repositories/shopping_list_repository.dart'; // Add this import
import '../../../service_locator.dart'; // Add this import
import '../cubit/shopping_list_cubit.dart';
import 'dart:developer';

class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Add BlocProvider at the screen level
    return BlocProvider(
      create: (context) => ShoppingListCubit(
        repository: getIt<IShoppingListRepository>(),
      ),
      child: const ShoppingListsView(),
    );
  }
}

// Extract the view content to a separate StatelessWidget
class ShoppingListsView extends StatelessWidget {
  const ShoppingListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Manage Stores',
            onPressed: () {
              context.push('/stores');
            },
          ),
        ],
      ),
      // Use BlocBuilder to react to state changes from the Cubit
      body: BlocBuilder<ShoppingListCubit, ShoppingListState>(
        builder: (context, state) {
          // ---- Loading State ----
          if (state is ShoppingListLoading || state is ShoppingListInitial) {
            log('State: Loading or Initial', name: 'ShoppingListsScreen');
            return const Center(child: CircularProgressIndicator());
          }
          // ---- Loaded State ----
          else if (state is ShoppingListLoaded) {
            log('State: Loaded with ${state.lists.length} lists', name: 'ShoppingListsScreen');
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
              itemBuilder: (listContext, index) {
                final list = state.lists[index];
                return Dismissible(
                  key: ValueKey(list.id),
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
                    context.read<ShoppingListCubit>().deleteList(
                          list.id,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
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
                        _showAddEditListDialog(context, list: list);
                      },
                    ),
                    onTap: () {
                      context.push('/list/${list.id}');
                    },
                  ),
                );
              },
            );
          }
          // ---- Error State ----
          else if (state is ShoppingListError) {
            log('State: Error - ${state.message}', name: 'ShoppingListsScreen', error: state.message);
            return Center(child: Text('Error loading lists: ${state.message}'));
          }
          // Fallback for any unhandled state
          log('State: Unknown - $state', name: 'ShoppingListsScreen');
          return const Center(child: Text('Something went wrong.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditListDialog(context);
        },
        tooltip: 'Add New List',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Move the dialog function to the view class
  Future<void> _showAddEditListDialog(
    BuildContext context, {
    ShoppingList? list,
  }) async {
    final cubit = context.read<ShoppingListCubit>();

    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: list?.name ?? '',
    );
    final bool isEditing = list != null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final listName = nameController.text.trim();
                  if (isEditing) {
                    cubit.renameList(list.id, listName);
                  } else {
                    cubit.addList(listName);
                  }
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