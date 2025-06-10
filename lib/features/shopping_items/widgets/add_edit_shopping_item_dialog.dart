import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:collection/collection.dart'; // Required for firstWhereOrNull

import '../../../models/models.dart';
import '../../../repositories/brand_repository.dart';
import '../../../repositories/price_entry_repository.dart';
import '../../../repositories/store_repository.dart';
import '../../../repositories/shopping_list_repository.dart'; // Added
import '../../../service_locator.dart';
import '../../../constants/app_constants.dart'; // Import AppConstants

class AddEditShoppingItemDialog extends StatefulWidget {
  final ShoppingItem? item;
  final Future<void> Function(ShoppingItem itemToSave) onPersistItem;
  final GroceryStore? initialStore; // Added: For when adding from ItemsByStoreScreen
  final int? shoppingListIdForNewItem; // Added: For when adding from ShoppingItemsScreen (list is fixed)


  const AddEditShoppingItemDialog({
    super.key,
    this.item,
    required this.onPersistItem,
    this.initialStore, // Added
    this.shoppingListIdForNewItem, // Added
  });

  @override
  State<AddEditShoppingItemDialog> createState() => _AddEditShoppingItemDialogState();
}

class _AddEditShoppingItemDialogState extends State<AddEditShoppingItemDialog> {
  final _storeRepository = getIt<IStoreRepository>();
  final _brandRepository = getIt<IBrandRepository>();
  final _priceEntryRepository = getIt<IPriceEntryRepository>();
  final _shoppingListRepository = getIt<IShoppingListRepository>(); // Added
  late bool _isEditing;

  // Form key and controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _newBrandNameController;
  late TextEditingController _priceController;
  late TextEditingController _newStoreNameController; // Added
  late TextEditingController _newShoppingListNameController; // Added

  // Key for BrandSelectionWidget
  final GlobalKey<_BrandSelectionWidgetState> _brandSelectionWidgetKey = GlobalKey<_BrandSelectionWidgetState>();

  // State needed within the dialog
  List<GroceryStore>? _allStores; // Will hold fetched stores
  int? _selectedStoreId;
  bool _isLoadingStores = true;
  String? _storeError;

  List<ShoppingList>? _allShoppingLists; // Added
  int? _selectedShoppingListId; // Added
  bool _isLoadingShoppingLists = true; // Added
  String? _shoppingListError; // Added

  int? _selectedBrandId; // Still managed here for _saveForm
  bool _showNewBrandField = false; // Still managed here
  bool _showNewStoreField = false; // Added
  bool _showNewShoppingListField = false; // Added

  // MARK: - Lifecycle Methods
  DateTime? _selectedDate = DateTime.now(); // Default to today for PriceEntry

  @override
  void initState() {
    super.initState();
    _isEditing = widget.item != null;

    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity.toString() ?? '1');
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
    _newBrandNameController = TextEditingController();
    _priceController = TextEditingController();
    _newStoreNameController = TextEditingController(); // Added
    _newShoppingListNameController = TextEditingController(); // Added

    if (widget.initialStore != null) { // If launched from ItemsByStoreScreen
      _selectedStoreId = widget.initialStore!.id;
      // _selectedShoppingListId will be chosen by the user from dropdown
    } else if (_isEditing && widget.item!.shoppingList.targetId != 0) { // Editing existing item
        _selectedShoppingListId = widget.item!.shoppingList.targetId;
        if (widget.item!.groceryStores.isNotEmpty) {
            _selectedStoreId = widget.item!.groceryStores.first.id;
        }
    } else if (!_isEditing && widget.shoppingListIdForNewItem != null) { // Adding new item from a specific list screen
        _selectedShoppingListId = widget.shoppingListIdForNewItem;
        // _selectedStoreId can be chosen by user or left null
    }


    _selectedBrandId = widget.item?.brand.targetId;

    if (widget.initialStore == null) { // Only fetch all stores if not pre-set
      _fetchStores();
    } else {
      _isLoadingStores = false; // Store is provided, no need to load all
      _allStores = [widget.initialStore!]; // Populate with the single store
    }
    _fetchShoppingLists(); // Added: Fetch shopping lists
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _newBrandNameController.dispose();
    _priceController.dispose();
    _newStoreNameController.dispose(); // Added
    _newShoppingListNameController.dispose(); // Added
    super.dispose();
  }

  // MARK: - Data Fetching
  Future<void> _fetchStores() async {
    try {
      final stores = await _storeRepository.getAllStores();
      if (mounted) {
        setState(() {
          _allStores = stores;
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _storeError = "Error loading stores: $e";
          _isLoadingStores = false;
        });
      }
    }
  }

  Future<void> _fetchShoppingLists() async { // Added method
    setState(() {
      _isLoadingShoppingLists = true;
      _shoppingListError = null;
    });
    try {
      final lists = await _shoppingListRepository.getAllLists(); // Assuming this method exists
      if (mounted) {
        setState(() {
          _allShoppingLists = lists;
          _isLoadingShoppingLists = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shoppingListError = "Error loading shopping lists: $e";
          _isLoadingShoppingLists = false;
        });
      }
    }
  }

  // MARK: - UI Event Handlers
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // MARK: - Form Submission
  Future<void> _saveForm() async {
    // Ensure new field validators are checked if those fields are visible
    if (_showNewShoppingListField && _newShoppingListNameController.text.trim().isEmpty) {
      _formKey.currentState!.validate(); // Trigger validation for the new list name field
      return;
    }
    if (_showNewStoreField && _newStoreNameController.text.trim().isEmpty) {
      _formKey.currentState!.validate(); // Trigger validation for the new store name field
      return;
    }
    // Brand field validation is handled by _BrandSelectionWidget's internal TextFormField

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final category = _categoryController.text.trim();
      final quantity = double.parse(_quantityController.text);
      final unit = _unitController.text.trim();

      int? finalBrandId = _selectedBrandId;
      if (_showNewBrandField && _newBrandNameController.text.isNotEmpty) {
        try {
          final newBrand = Brand(name: _newBrandNameController.text.trim());
          finalBrandId = await _brandRepository.addBrand(newBrand);
          await _brandSelectionWidgetKey.currentState?.refreshBrands(); // Refresh brand list
          setState(() {
            _selectedBrandId = finalBrandId; // Ensure the new brand is selected
            _showNewBrandField = false; // Hide the new brand field
            _newBrandNameController.clear();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error adding new brand: $e")),
            );
          }
          return; // Don't proceed if brand creation fails
        }
      }

      // Handle new Shopping List creation (only for new items or if explicitly adding new)
      if (_showNewShoppingListField && _newShoppingListNameController.text.isNotEmpty) {
        try {
          final newListName = _newShoppingListNameController.text.trim();
          final newList = ShoppingList(name: newListName);
          final newListId = await _shoppingListRepository.addList(newList);
          await _fetchShoppingLists(); // Refresh the list
          setState(() {
            _selectedShoppingListId = newListId; // Select the new list
            _showNewShoppingListField = false; // Hide the new list field
            _newShoppingListNameController.clear();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error adding new shopping list: $e")),
            );
          }
          return;
        }
      }

      // Handle new Store creation
      int? finalSelectedStoreId = _selectedStoreId;
      if (_showNewStoreField && _newStoreNameController.text.isNotEmpty) {
        try {
          final newStoreName = _newStoreNameController.text.trim();
          final newStore = GroceryStore(name: newStoreName);
          final newStoreId = await _storeRepository.addStore(newStore);
          await _fetchStores(); // Refresh the list
          setState(() {
            _selectedStoreId = newStoreId; // Select the new store
            finalSelectedStoreId = newStoreId;
            _showNewStoreField = false; // Hide the new store field
            _newStoreNameController.clear();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error adding new store: $e")),
            );
          }
          return;
        }
      }

      ShoppingItem shoppingItemToSave;
      if (_isEditing) {
        shoppingItemToSave = widget.item!;
        shoppingItemToSave.name = name;
        shoppingItemToSave.category = category;
        shoppingItemToSave.quantity = quantity;
        shoppingItemToSave.unit = unit;
        // Shopping list for an existing item should not change here
        // It's managed by the cubit that owns the item (e.g. ShoppingItemCubit)
      } else { // Adding a new item
        shoppingItemToSave = ShoppingItem(
          name: name,
          category: category,
          quantity: quantity,
          unit: unit,
          isCompleted: false,
        );
        // Assign shopping list
        if (_selectedShoppingListId != null) {
          shoppingItemToSave.shoppingList.targetId = _selectedShoppingListId;
        } else {
          // This case should be prevented by form validation if adding from ItemsByStoreScreen
          // or if not adding a new list.
          if (mounted && !_showNewShoppingListField) { // Only show error if not in process of adding new
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: Shopping list not selected.")),
            );
          }
          return;
        }
      }

      if (finalBrandId != null) {
        shoppingItemToSave.brand.targetId = finalBrandId;
      } else {
        shoppingItemToSave.brand.targetId = 0;
      }

      shoppingItemToSave.groceryStores.clear();
      if (finalSelectedStoreId != null && _allStores != null) {
        final storeToAdd = _allStores!.firstWhereOrNull((s) => s.id == finalSelectedStoreId);
        if (storeToAdd != null) {
          shoppingItemToSave.groceryStores.add(storeToAdd);
        }
      } else if (widget.initialStore != null && finalSelectedStoreId == widget.initialStore!.id) {
         shoppingItemToSave.groceryStores.add(widget.initialStore!);
      }


      // Persist the item using the callback
      await widget.onPersistItem(shoppingItemToSave);

      if (_priceController.text.isNotEmpty && _selectedDate != null) {
        final price = double.tryParse(_priceController.text);
        if (price != null && price > 0) {
          final newPriceEntry = PriceEntry(
            price: price,
            date: _selectedDate!,
            canonicalItemName: name,
          );
          if (finalSelectedStoreId != null) {
            newPriceEntry.groceryStore.targetId = finalSelectedStoreId;
          }
          if (finalBrandId != null) {
            newPriceEntry.brand.targetId = finalBrandId;
          }
          try {
            await _priceEntryRepository.addPriceEntry(newPriceEntry);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error saving price entry: $e")),
              );
            }
          }
        }
      }
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
      }
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Item' : 'Add New Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Item Name*',
                  hintText: 'e.g., Milk',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity*',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter quantity';
                        if (double.tryParse(value) == null) return 'Invalid number';
                        if (double.parse(value) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Unit*',
                        hintText: 'e.g., gallon, box, lbs',
                        border: OutlineInputBorder(),
                      ),
                      value: _unitController.text.isNotEmpty && AppConstants.predefinedUnits.contains(_unitController.text)
                          ? _unitController.text
                          : null,
                      items: AppConstants.predefinedUnits.map((String unit) {
                        return DropdownMenuItem<String>( // Create DropdownMenuItem
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _unitController.text = newValue ?? '';
                        });
                      },
                      validator: (value) { // Added validator back
                        if (value == null || value.isEmpty) {
                          return 'Please select a unit';
                        }
                        return null;
                      },
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category*',
                  hintText: 'e.g., Dairy, Produce',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter category'
                    : null,
              ),
              const Divider(height: 30, thickness: 1),

              // Shopping List Selector (if adding from ItemsByStoreScreen or if no list pre-selected for new item)
              if (!_isEditing && (widget.initialStore != null || widget.shoppingListIdForNewItem == null)) ...[
                const Text('Add to Shopping List:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingShoppingLists)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                if (_shoppingListError != null)
                  Text(_shoppingListError!, style: const TextStyle(color: Colors.red)),
                if (!_isLoadingShoppingLists && _shoppingListError == null)
                  (_allShoppingLists == null || _allShoppingLists!.isEmpty) && !_showNewShoppingListField
                      ?  Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              const Text(
                                'No shopping lists found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                              // Show "Add New Shopping List" button directly here if no lists and not already adding
                              TextButton.icon(
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Add New Shopping List'),
                                onPressed: () {
                                  setState(() {
                                    _showNewShoppingListField = true;
                                    _selectedShoppingListId = null; 
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : _showNewShoppingListField
                          ? Column( 
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _newShoppingListNameController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'New Shopping List Name*',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (_showNewShoppingListField && (value == null || value.trim().isEmpty)) {
                                      return 'Enter a list name';
                                    }
                                    return null;
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        setState(() {
                                          _showNewShoppingListField = false;
                                          _newShoppingListNameController.clear();
                                          // Re-select original if available and was for new item
                                          if (!_isEditing && widget.shoppingListIdForNewItem != null) {
                                            _selectedShoppingListId = widget.shoppingListIdForNewItem;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Shopping List*',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedShoppingListId,
                              hint: const Text('Choose a list'),
                              isExpanded: true,
                              items: _allShoppingLists?.map((list) {
                                return DropdownMenuItem<int>(
                                  value: list.id,
                                  child: Text(list.name),
                                );
                              }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedShoppingListId = value;
                                });
                              },
                              validator: (value) {
                                if (!_isEditing && widget.shoppingListIdForNewItem == null && value == null && !_showNewShoppingListField) {
                                  return 'Please select a shopping list';
                                }
                                return null;
                              },
                            ),
                if (!_isLoadingShoppingLists && _shoppingListError == null && !_showNewShoppingListField && !(_allShoppingLists == null || _allShoppingLists!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add New Shopping List'),
                      onPressed: () {
                        setState(() {
                          _showNewShoppingListField = true;
                          _selectedShoppingListId = null; 
                        });
                      },
                       style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ),
                  ),
                const Divider(height: 30, thickness: 1),
              ],

              // Store Information / Selector
              if (widget.initialStore != null && !_showNewStoreField) ...[
                const Text('Store:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.initialStore!.name, style: Theme.of(context).textTheme.titleMedium),
              ] else ...[ 
                const Text('Store to purchase at:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingStores)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                if (_storeError != null)
                  Text(_storeError!, style: const TextStyle(color: Colors.red)),
                if (!_isLoadingStores && _storeError == null)
                  (_allStores == null || _allStores!.isEmpty) && !_showNewStoreField
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              const Text(
                                'No stores saved yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                              // Show "Add New Store" button directly here if no stores and not already adding
                              TextButton.icon(
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Add New Store'),
                                onPressed: () {
                                  setState(() {
                                    _showNewStoreField = true;
                                    _selectedStoreId = null; 
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : _showNewStoreField
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _newStoreNameController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'New Store Name*',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (_showNewStoreField && (value == null || value.trim().isEmpty)) {
                                      return 'Enter a store name';
                                    }
                                    return null;
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        setState(() {
                                          _showNewStoreField = false;
                                          _newStoreNameController.clear();
                                          if (widget.initialStore != null) {
                                            _selectedStoreId = widget.initialStore!.id;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Store', 
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedStoreId,
                              hint: const Text('Select a store (optional)'),
                              isExpanded: true,
                              items: _allStores?.map((store) {
                                return DropdownMenuItem<int>(
                                  value: store.id,
                                  child: Text(store.name),
                                );
                              }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStoreId = value;
                                });
                              },
                            ),
                if (!_isLoadingStores && _storeError == null && !_showNewStoreField && widget.initialStore == null && !(_allStores == null || _allStores!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add New Store'),
                      onPressed: () {
                        setState(() {
                          _showNewStoreField = true;
                          _selectedStoreId = null; 
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
              const Divider(height: 30, thickness: 1),
              const Text('Brand:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _BrandSelectionWidget(
                key: _brandSelectionWidgetKey, // Assign the key here
                brandRepository: _brandRepository,
                initialBrandId: _selectedBrandId,
                newBrandNameController: _newBrandNameController,
                showNewBrandField: _showNewBrandField,
                onBrandSelected: (brandId) {
                  setState(() {
                    _selectedBrandId = brandId;
                  });
                },
                onToggleShowNewBrandField: () {
                  setState(() {
                    _showNewBrandField = !_showNewBrandField;
                    if (!_showNewBrandField) {
                      _newBrandNameController.clear(); 
                    }
                  });
                },
              ),
              const Divider(height: 30, thickness: 1),
              const Text('Log Price:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g., 2.99',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) return 'Invalid price';
                    if (double.parse(value) <= 0) return 'Price must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Date: Not set'
                          : 'Date: ${DateFormat.yMd().format(_selectedDate!)}',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Select Date'),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: _saveForm,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// MARK: - _BrandSelectionWidget
// --- Brand Selection Widget ---
class _BrandSelectionWidget extends StatefulWidget {
  final IBrandRepository brandRepository;
  final int? initialBrandId;
  final TextEditingController newBrandNameController;
  final bool showNewBrandField;
  final ValueChanged<int?> onBrandSelected;
  final VoidCallback onToggleShowNewBrandField;

  const _BrandSelectionWidget({
    super.key, // Pass the key to the super constructor
    required this.brandRepository,
    this.initialBrandId,
    required this.newBrandNameController,
    required this.showNewBrandField,
    required this.onBrandSelected,
    required this.onToggleShowNewBrandField,
  });

  @override
  State<_BrandSelectionWidget> createState() => _BrandSelectionWidgetState();
}

class _BrandSelectionWidgetState extends State<_BrandSelectionWidget> {
  List<Brand>? _allBrands;
  bool _isLoadingBrands = true;
  String? _brandError;
  int? _currentSelectedBrandId;

  // Method to allow parent to trigger a refresh
  Future<void> refreshBrands() async {
    await _fetchBrands();
  }

  // MARK: - Lifecycle Methods (BrandSelectionWidget)
  @override
  void initState() {
    super.initState();
    _currentSelectedBrandId = widget.initialBrandId;
    _fetchBrands();
  }

  @override
  void didUpdateWidget(covariant _BrandSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBrandId != oldWidget.initialBrandId) {
      _currentSelectedBrandId = widget.initialBrandId;
    }
  }

  // MARK: - Data Fetching (BrandSelectionWidget)
  Future<void> _fetchBrands() async {
    setState(() {
      _isLoadingBrands = true;
      _brandError = null;
    });
    try {
      final brands = await widget.brandRepository.getAllBrands();
      if (mounted) {
        setState(() {
          _allBrands = brands;
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _brandError = "Error loading brands: $e";
          _isLoadingBrands = false;
        });
      }
    }
  }

  // MARK: - Build Method (BrandSelectionWidget)
  @override
  Widget build(BuildContext context) {
    if (widget.showNewBrandField) {
      // When adding a new brand, only show the text field and cancel button
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.newBrandNameController,
            decoration: const InputDecoration(
              labelText: 'New Brand Name',
              hintText: 'Enter brand name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (widget.showNewBrandField && (value == null || value.trim().isEmpty)) {
                return 'Enter a name for the new brand';
              }
              return null;
            },
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel New Brand'),
            onPressed: widget.onToggleShowNewBrandField,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    }

    // When selecting an existing brand or choosing to add a new one
    if (_isLoadingBrands) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_brandError != null) {
      return Column(
        children: [
          Text(_brandError!, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _fetchBrands, child: const Text("Retry")),
        ],
      );
    }

    List<DropdownMenuItem<int?>> dropdownItems = [
      const DropdownMenuItem<int?>(
        value: 0, // Represent "No Brand" or "Generic" with value 0
        child: Text("No Brand / Generic"),
      ),
    ];

    if (_allBrands != null) {
      for (var brand in _allBrands!) {
        dropdownItems.add(DropdownMenuItem<int?>(
          value: brand.id,
          child: Text(brand.name),
        ));
      }
    }

    int? currentValue = _currentSelectedBrandId;
    if (!dropdownItems.any((item) => item.value == currentValue)) {
      currentValue = 0; 
    }
    

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          decoration: const InputDecoration(
            labelText: 'Select Brand',
            border: OutlineInputBorder(),
          ),
          value: currentValue,
          hint: const Text('Optional'),
          isExpanded: true,
          items: dropdownItems,
          onChanged: (value) {
            setState(() {
              _currentSelectedBrandId = value;
            });
            widget.onBrandSelected(value);
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add New Brand'),
          onPressed: widget.onToggleShowNewBrandField,
           style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ),
      ],
    );
  }
}

