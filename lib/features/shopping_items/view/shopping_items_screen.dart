// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/common_widgets/empty_list_widget.dart'; // Added import
import 'package:smart_shopper/common_widgets/loading_indicator.dart';
import 'package:smart_shopper/common_widgets/error_display.dart';
import 'package:smart_shopper/features/shopping_items/cubit/shopping_item_cubit.dart';
import 'package:smart_shopper/features/shopping_items/widgets/shopping_item_list_view.dart';
// import 'package:smart_shopper/features/shopping_items/widgets/add_edit_shopping_item_dialog.dart'; // Removed unused import
import 'package:smart_shopper/models/shopping_item.dart'; // Added import
import 'package:smart_shopper/service_locator.dart';
import 'package:smart_shopper/repositories/shopping_item_repository.dart';
import 'package:smart_shopper/services/llm_service.dart'; // Import LlmService
import 'dart:convert'; // Import for jsonDecode
import 'package:smart_shopper/tools/logger.dart'; // Import logger

class ShoppingItemsScreen extends StatelessWidget {
  final int listId; // Received from the router

  const ShoppingItemsScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit. We create it manually here, passing the listId
    // and fetching the repository from GetIt.
    return BlocProvider(
      create: (context) => ShoppingItemCubit(
        repository: getIt<IShoppingItemRepository>(), // Get repo from DI
        listId: listId, // Pass the listId from the route
      ),
      child: const ShoppingItemView(), // Made const
    );
  }
}

// Separate View widget to easily access the Cubit context below the provider
class ShoppingItemView extends StatefulWidget { // Changed to StatefulWidget
  const ShoppingItemView({super.key});

  @override
  State<ShoppingItemView> createState() => _ShoppingItemViewState(); // Create state
}

class _ShoppingItemViewState extends State<ShoppingItemView> { // State class
  final TextEditingController _itemController = TextEditingController(); // Controller for the TextField
  final FocusNode _itemFocusNode = FocusNode(); // FocusNode for the TextField
  bool _isProcessing = false; // State variable to track processing

  @override
  void dispose() {
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addItem() async { // Changed to Future<void> and async
    final itemName = _itemController.text.trim();
    if (itemName.isNotEmpty) {
      setState(() {
        _isProcessing = true; // Start processing
      });

      final llmService = getIt<LlmService>();
      try {
        final currentContext = context; // Capture the BuildContext
        String? parsedJsonString = await llmService.parseShoppingListItem(itemName);

        if (!mounted) return; // Ensure the widget is still in the tree

        if (parsedJsonString != null) {
          // Improved cleaning logic for Markdown code block delimiters
          parsedJsonString = parsedJsonString.trim(); // Trim initial whitespace

          if (parsedJsonString.startsWith("```json")) {
            // Remove ```json prefix and trim resulting string
            parsedJsonString = parsedJsonString.substring(7).trim();
          }

          if (parsedJsonString.endsWith("```")) {
            // Remove ``` suffix and trim resulting string
            parsedJsonString = parsedJsonString.substring(0, parsedJsonString.length - 3).trim();
          }

          try {
            final parsedData = jsonDecode(parsedJsonString) as Map<String, dynamic>;
            final parsedItem = ParsedShoppingItem.fromJson(parsedData);

            final newItem = ShoppingItem(
              name: parsedItem.name,
              category: parsedItem.category, // Assign category from parsed data
              unit: parsedItem.unit, // Assign unit from parsed data
              quantity: parsedItem.quantity ?? 1.0, // Assign quantity, default to 1.0 if null
            );
            currentContext.read<ShoppingItemCubit>().addItem(newItem);
          } catch (e) {
            logError('Error parsing LLM response: $e. Original response: $parsedJsonString');
            // Fallback to adding the item as is
            final newItem = ShoppingItem(name: itemName);
            // ignore: use_build_context_synchronously
            context.read<ShoppingItemCubit>().addItem(newItem);
          }
        } else {
          // Fallback to adding the item as is if LLM parsing fails
          final newItem = ShoppingItem(name: itemName);
          // ignore: use_build_context_synchronously
          context.read<ShoppingItemCubit>().addItem(newItem);
        }
      } catch (e) {
        logError('Error calling LLM service: $e');
        // Fallback to adding the item as is
        final newItem = ShoppingItem(name: itemName);
        // ignore: use_build_context_synchronously
        context.read<ShoppingItemCubit>().addItem(newItem);
      } finally {
        _itemController.clear(); // Clear the text field
        // Delay focus request slightly to ensure UI has settled
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) { // Check if the widget is still in the tree
            _itemFocusNode.requestFocus();
          }
        });
        setState(() {
          _isProcessing = false; // End processing
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
          builder: (context, state) {
            if (state is ShoppingItemLoaded) {
              // Assuming parentList might be null initially or not always present
              return Text(state.parentList.name); // Removed unnecessary null-aware operator as per error
            }
            return const Text('Shopping Items');
          },
        ),
        actions: [
          BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
            builder: (context, state) {
              if (state is ShoppingItemLoaded) {
                return IconButton(
                  icon: Icon(state.showCompletedItems ? Icons.visibility : Icons.visibility_off),
                  tooltip: state.showCompletedItems ? 'Hide Completed' : 'Show Completed',
                  onPressed: () {
                    context.read<ShoppingItemCubit>().toggleShowCompletedItems();
                  },
                );
              }
              return const SizedBox.shrink(); // Return empty if not loaded
            },
          ),
          BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
            builder: (context, state) {
              if (state is ShoppingItemLoaded) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'groupByCategory') {
                      context.read<ShoppingItemCubit>().toggleGroupByCategory();
                    } else if (value == 'groupByStore') {
                      context.read<ShoppingItemCubit>().toggleGroupByStore();
                    } else if (value == 'uncheckAll') {
                      context.read<ShoppingItemCubit>().uncheckAllItems();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'groupByCategory',
                      child: Text(state.groupByCategory ? 'Ungroup by Category' : 'Group by Category'),
                    ),
                    PopupMenuItem<String>(
                      value: 'groupByStore',
                      child: Text(state.groupByStore ? 'Ungroup by Store' : 'Group by Store'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'uncheckAll',
                      child: Text('Uncheck All Items'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink(); // Return empty if not loaded
            },
          ),
        ],
      ),
      body: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
        builder: (context, state) {
          if (state is ShoppingItemInitial) {
            return const LoadingIndicator();
          } else if (state is ShoppingItemLoading) {
            return const LoadingIndicator();
          } else if (state is ShoppingItemLoaded) {
            if (state.items.isEmpty && !state.showCompletedItems) {
              // Show empty list message only if no items and not showing completed
              return Column( // Added Column to include TextField
                children: [
                  Expanded(
                    child: EmptyListWidget(
                      message:
                          'This list is empty. Add items using the bar below.',
                    ),
                  ),
                  _buildAddItemBar(), // Add the text bar
                ],
              );
            }
            return Column( // Wrap existing list and new bar in a Column
              children: [
                Expanded(child: const ShoppingItemListView()),
                _buildAddItemBar(), // Add the text bar
              ],
            );
          } else if (state is ShoppingItemError) {
            return ErrorDisplay(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
      // floatingActionButton: FloatingActionButton( // REMOVE FloatingActionButton
      //   onPressed: () {
      //     showDialog(
      //       context: context,
      //       builder: (_) => AddEditShoppingItemDialog(
      //         shoppingListIdForNewItem: context.read<ShoppingItemCubit>().listId, 
      //         onPersistItem: (item) async {
      //           await context.read<ShoppingItemCubit>().addItem(item);
      //         },
      //       ),
      //     );
      //   },
      //   tooltip: 'Add Item',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  // Helper widget for the persistent add item bar
  Widget _buildAddItemBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _itemController,
              focusNode: _itemFocusNode,
              decoration: const InputDecoration(
                hintText: 'Add item name...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _isProcessing ? null : _addItem(), // Add item on enter, disable if processing
              enabled: !_isProcessing, // Disable TextField if processing
            ),
          ),
          const SizedBox(width: 8),
          _isProcessing
              ? const CircularProgressIndicator() // Show progress indicator
              : IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem, // Add item on button tap
                  tooltip: 'Add Item',
                ),
        ],
      ),
    );
  }
}
