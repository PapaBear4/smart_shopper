import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:collection/collection.dart'; // Required for firstWhereOrNull

import '../../../models/models.dart';
import '../../../repositories/brand_repository.dart';
import '../../../repositories/price_entry_repository.dart';
import '../../../repositories/store_repository.dart';
import '../../../service_locator.dart';
import '../cubit/shopping_item_cubit.dart';
import '../../../constants/app_constants.dart'; // Import AppConstants

class AddEditShoppingItemDialog extends StatefulWidget {
  final ShoppingItem? item;
  final ShoppingItemCubit shoppingItemCubit; // Add this

  const AddEditShoppingItemDialog({
    super.key,
    this.item,
    required this.shoppingItemCubit, // Require in constructor
  });

  @override
  State<AddEditShoppingItemDialog> createState() => _AddEditShoppingItemDialogState();
}

class _AddEditShoppingItemDialogState extends State<AddEditShoppingItemDialog> {
  // Get the necessary cubit and repository instances from the context/DI
  late final ShoppingItemCubit _cubit;
  final _storeRepository = getIt<IStoreRepository>(); // To fetch stores
  final _brandRepository = getIt<IBrandRepository>(); // To fetch brands
  final _priceEntryRepository = getIt<IPriceEntryRepository>(); // To add price entries
  late bool _isEditing;

  // Form key and controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _newBrandNameController;
  late TextEditingController _priceController;

  // State needed within the dialog
  List<GroceryStore>? _allStores; // Will hold fetched stores
  int? _selectedStoreId;
  bool _isLoadingStores = true;
  String? _storeError;

  // List<Brand>? _allBrands; // Moved to _BrandSelectionWidget
  int? _selectedBrandId; // Still managed here for _saveForm
  // bool _isLoadingBrands = true; // Moved to _BrandSelectionWidget
  // String? _brandError; // Moved to _BrandSelectionWidget
  bool _showNewBrandField = false; // Still managed here

  // MARK: - Lifecycle Methods
  DateTime? _selectedDate = DateTime.now(); // Default to today for PriceEntry

  @override
  void initState() {
    super.initState();
    _cubit = widget.shoppingItemCubit; // Use the passed cubit instance
    _isEditing = widget.item != null;

    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity.toString() ?? '1');
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
    _newBrandNameController = TextEditingController();
    _priceController = TextEditingController();

    _selectedStoreId = _isEditing && widget.item!.groceryStores.isNotEmpty
        ? widget.item!.groceryStores.first.id
        : null;
    _selectedBrandId = widget.item?.brand.targetId;

    _fetchStores();
    // _fetchBrands(); // Moved to _BrandSelectionWidget
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _newBrandNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // MARK: - Data Fetching
  // --- Fetch stores function ---
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
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error adding new brand: $e")),
            );
          }
          return; // Don't proceed if brand creation fails
        }
      }

      ShoppingItem shoppingItemToSave;
      if (_isEditing) {
        shoppingItemToSave = widget.item!;
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

      if (finalBrandId != null) {
        shoppingItemToSave.brand.targetId = finalBrandId;
      } else {
        shoppingItemToSave.brand.targetId = 0;
      }

      shoppingItemToSave.groceryStores.clear();
      if (_selectedStoreId != null && _allStores != null) {
        final storeToAdd = _allStores!.firstWhereOrNull((s) => s.id == _selectedStoreId);
        if (storeToAdd != null) {
          shoppingItemToSave.groceryStores.add(storeToAdd);
        }
      }

      if (_isEditing) {
        await _cubit.updateItem(shoppingItemToSave);
      } else {
        await _cubit.addItem(shoppingItemToSave);
      }

      if (_priceController.text.isNotEmpty && _selectedDate != null) {
        final price = double.tryParse(_priceController.text);
        if (price != null && price > 0) {
          final newPriceEntry = PriceEntry(
            price: price,
            date: _selectedDate!,
            canonicalItemName: name,
          );
          if (_selectedStoreId != null) {
            newPriceEntry.groceryStore.targetId = _selectedStoreId;
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
              const Text('Store to purchase at:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_isLoadingStores)
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              if (_storeError != null)
                Text(_storeError!, style: const TextStyle(color: Colors.red)),
              if (!_isLoadingStores && _storeError == null)
                (_allStores == null || _allStores!.isEmpty)
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No stores saved yet.\\nAdd stores via Manage Stores screen first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Select Store',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedStoreId,
                        hint: const Text('Select a store'),
                        isExpanded: true,
                        items: _allStores!.map((store) {
                          return DropdownMenuItem<int>(
                            value: store.id,
                            child: Text(store.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStoreId = value;
                          });
                        },
                      ),
              const Divider(height: 30, thickness: 1),
              const Text('Brand:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _BrandSelectionWidget(
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
                      _newBrandNameController.clear(); // Clear text if hiding field
                      // If a brand was selected before showing new brand field,
                      // ensure it remains selected or clear _selectedBrandId if new brand was focused.
                      // This might need more nuanced handling based on exact UX desired.
                    }
                  });
                },
              ),
              // --- MOVED BRAND SELECTION UI TO _BrandSelectionWidget ---
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
    // If showNewBrandField becomes false, and it was true,
    // it means the parent dialog cancelled adding a new brand.
    // We might want to reset the dropdown if a new brand was being typed.
    // if (oldWidget.showNewBrandField && !widget.showNewBrandField) {
        // If nothing was selected from dropdown and new brand field is cancelled,
        // ensure _currentSelectedBrandId is null or reflects previous valid selection.
        // This logic depends on how parent wants to manage _selectedBrandId upon cancelling new brand.
        // For now, we assume parent handles _selectedBrandId correctly.
    // }
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

    // Ensure _currentSelectedBrandId is a valid value present in dropdownItems.
    // If _currentSelectedBrandId is null, and we use 0 for "No Brand", map null to 0 for consistency if needed.
    // However, item.brand.targetId defaults to 0, so _currentSelectedBrandId will likely be 0 rather than null for "no brand".
    int? currentValue = _currentSelectedBrandId;
    if (!dropdownItems.any((item) => item.value == currentValue)) {
      // If current value (e.g. a deleted brand ID) isn't in the list, default to "No Brand" (0)
      // or null if 0 isn't explicitly handled as "No Brand"
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
            // contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Adjust padding if needed
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
          // validator: (value) { // Optional: if brand selection is mandatory
          //   if (value == null) return 'Please select a brand';
          //   return null;
          // },
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

