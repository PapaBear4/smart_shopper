import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_shopper/models/models.dart';
import 'package:smart_shopper/features/product_variants/cubit/product_variant_cubit.dart'; // This should bring in ProductVariantState and related classes
import 'package:smart_shopper/features/brands/cubit/brand_cubit.dart';
import 'package:smart_shopper/service_locator.dart';

class ProductVariantFormScreen extends StatefulWidget {
  final ProductVariant? productVariant;

  const ProductVariantFormScreen({super.key, this.productVariant});

  static const routeName = '/product-variant-form';

  @override
  State<ProductVariantFormScreen> createState() => _ProductVariantFormScreenState();
}

class _ProductVariantFormScreenState extends State<ProductVariantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ProductVariantCubit _productVariantCubit;
  late BrandCubit _brandCubit;

  // TextEditingControllers for String fields
  late TextEditingController _nameController;
  late TextEditingController _baseProductNameController;
  late TextEditingController _upcCodeController;
  late TextEditingController _formController;
  late TextEditingController _packageSizeController;
  late TextEditingController _containerTypeController;
  late TextEditingController _preparationController;
  late TextEditingController _maturityController;
  late TextEditingController _gradeController;
  late TextEditingController _flavorController;
  late TextEditingController _scentController;
  late TextEditingController _colorController;
  late TextEditingController _mainIngredientController;
  late TextEditingController _spicinessLevelController;
  late TextEditingController _caffeineContentController;
  late TextEditingController _alcoholContentController;
  late TextEditingController _subBrandController;
  late TextEditingController _productLineController;

  // TextEditingControllers for List<String> fields
  late TextEditingController _allergenInfoController;
  late TextEditingController _secondaryIngredientsController;
  late TextEditingController _customAttributesController;

  // Boolean state variables
  bool _isOrganic = false;
  bool _isGlutenFree = false;
  bool _isNonGMO = false;
  bool _isVegan = false;
  bool _isVegetarian = false;
  bool _isDairyFree = false;
  bool _isNutFree = false;
  bool _isSoyFree = false;
  bool _isKosher = false;
  bool _isHalal = false;
  bool _isSugarFree = false;
  bool _isLowSodium = false;
  bool _isLowFat = false;
  bool _isLowCarb = false;
  bool _isHighProtein = false;
  bool _isWholeGrain = false;
  bool _hasNoAddedSugar = false;
  bool _hasArtificialSweeteners = false;

  int? _selectedBrandId;
  bool _isEditMode = false;
  bool _isSaving = false; // Add a saving state variable

  @override
  void initState() {
    super.initState();
    _productVariantCubit = getIt<ProductVariantCubit>();
    _brandCubit = getIt<BrandCubit>(); 
    // BrandCubit constructor calls _loadBrands(), so it should be loading.

    _isEditMode = widget.productVariant != null;
    final pv = widget.productVariant;

    _nameController = TextEditingController(text: pv?.name ?? '');
    _baseProductNameController = TextEditingController(text: pv?.baseProductName ?? '');
    _upcCodeController = TextEditingController(text: pv?.upcCode ?? '');
    _formController = TextEditingController(text: pv?.form ?? '');
    _packageSizeController = TextEditingController(text: pv?.packageSize ?? '');
    _containerTypeController = TextEditingController(text: pv?.containerType ?? '');
    _preparationController = TextEditingController(text: pv?.preparation ?? '');
    _maturityController = TextEditingController(text: pv?.maturity ?? '');
    _gradeController = TextEditingController(text: pv?.grade ?? '');
    _flavorController = TextEditingController(text: pv?.flavor ?? '');
    _scentController = TextEditingController(text: pv?.scent ?? '');
    _colorController = TextEditingController(text: pv?.color ?? '');
    _mainIngredientController = TextEditingController(text: pv?.mainIngredient ?? '');
    _spicinessLevelController = TextEditingController(text: pv?.spicinessLevel ?? '');
    _caffeineContentController = TextEditingController(text: pv?.caffeineContent ?? '');
    _alcoholContentController = TextEditingController(text: pv?.alcoholContent ?? '');
    _subBrandController = TextEditingController(text: pv?.subBrand ?? '');
    _productLineController = TextEditingController(text: pv?.productLine ?? '');

    _allergenInfoController = TextEditingController(text: pv?.allergenInfo.join(', ') ?? '');
    _secondaryIngredientsController = TextEditingController(text: pv?.secondaryIngredients.join(', ') ?? '');
    _customAttributesController = TextEditingController(text: pv?.customAttributes.join(', ') ?? '');

    if (pv != null) {
      _isOrganic = pv.isOrganic;
      _isGlutenFree = pv.isGlutenFree;
      _isNonGMO = pv.isNonGMO;
      _isVegan = pv.isVegan;
      _isVegetarian = pv.isVegetarian;
      _isDairyFree = pv.isDairyFree;
      _isNutFree = pv.isNutFree;
      _isSoyFree = pv.isSoyFree;
      _isKosher = pv.isKosher;
      _isHalal = pv.isHalal;
      _isSugarFree = pv.isSugarFree;
      _isLowSodium = pv.isLowSodium;
      _isLowFat = pv.isLowFat;
      _isLowCarb = pv.isLowCarb;
      _isHighProtein = pv.isHighProtein;
      _isWholeGrain = pv.isWholeGrain;
      _hasNoAddedSugar = pv.hasNoAddedSugar;
      _hasArtificialSweeteners = pv.hasArtificialSweeteners;
      _selectedBrandId = pv.brand.targetId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseProductNameController.dispose();
    _upcCodeController.dispose();
    _formController.dispose();
    _packageSizeController.dispose();
    _containerTypeController.dispose();
    _preparationController.dispose();
    _maturityController.dispose();
    _gradeController.dispose();
    _flavorController.dispose();
    _scentController.dispose();
    _colorController.dispose();
    _mainIngredientController.dispose();
    _spicinessLevelController.dispose();
    _caffeineContentController.dispose();
    _alcoholContentController.dispose();
    _subBrandController.dispose();
    _productLineController.dispose();
    _allergenInfoController.dispose();
    _secondaryIngredientsController.dispose();
    _customAttributesController.dispose();
    super.dispose();
  }

  List<String> _parseListString(String text) {
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSaving = true; // Set saving state to true
      });

      final newOrUpdatedVariant = ProductVariant(
        id: widget.productVariant?.id ?? 0,
        name: _nameController.text,
        baseProductName: _baseProductNameController.text,
        upcCode: _upcCodeController.text.isNotEmpty ? _upcCodeController.text : null,
        form: _formController.text.isNotEmpty ? _formController.text : null,
        packageSize: _packageSizeController.text.isNotEmpty ? _packageSizeController.text : null,
        containerType: _containerTypeController.text.isNotEmpty ? _containerTypeController.text : null,
        preparation: _preparationController.text.isNotEmpty ? _preparationController.text : null,
        maturity: _maturityController.text.isNotEmpty ? _maturityController.text : null,
        grade: _gradeController.text.isNotEmpty ? _gradeController.text : null,
        flavor: _flavorController.text.isNotEmpty ? _flavorController.text : null,
        scent: _scentController.text.isNotEmpty ? _scentController.text : null,
        color: _colorController.text.isNotEmpty ? _colorController.text : null,
        mainIngredient: _mainIngredientController.text.isNotEmpty ? _mainIngredientController.text : null,
        spicinessLevel: _spicinessLevelController.text.isNotEmpty ? _spicinessLevelController.text : null,
        caffeineContent: _caffeineContentController.text.isNotEmpty ? _caffeineContentController.text : null,
        alcoholContent: _alcoholContentController.text.isNotEmpty ? _alcoholContentController.text : null,
        subBrand: _subBrandController.text.isNotEmpty ? _subBrandController.text : null,
        productLine: _productLineController.text.isNotEmpty ? _productLineController.text : null,
        
        allergenInfo: _parseListString(_allergenInfoController.text),
        secondaryIngredients: _parseListString(_secondaryIngredientsController.text),
        customAttributes: _parseListString(_customAttributesController.text),

        isOrganic: _isOrganic,
        isGlutenFree: _isGlutenFree,
        isNonGMO: _isNonGMO,
        isVegan: _isVegan,
        isVegetarian: _isVegetarian,
        isDairyFree: _isDairyFree,
        isNutFree: _isNutFree,
        isSoyFree: _isSoyFree,
        isKosher: _isKosher,
        isHalal: _isHalal,
        isSugarFree: _isSugarFree,
        isLowSodium: _isLowSodium,
        isLowFat: _isLowFat,
        isLowCarb: _isLowCarb,
        isHighProtein: _isHighProtein,
        isWholeGrain: _isWholeGrain,
        hasNoAddedSugar: _hasNoAddedSugar,
        hasArtificialSweeteners: _hasArtificialSweeteners,
      );

      if (_selectedBrandId != null) {
        newOrUpdatedVariant.brand.targetId = _selectedBrandId!;
      }

      if (_isEditMode) {
        _productVariantCubit.updateProductVariant(newOrUpdatedVariant);
      } else {
        _productVariantCubit.addProductVariant(newOrUpdatedVariant);
      }
      // Navigator.of(context).pop(); // Moved to BlocListener
    }
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool isRequired = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $label.';
        }
        return null;
      },
    );
  }

  Widget _buildSwitchListTile(String title, bool currentValue, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: currentValue,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product Variant' : 'Add Product Variant'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveForm,
            ),
        ],
      ),
      body: BlocListener<ProductVariantCubit, ProductVariantState>(
        bloc: _productVariantCubit,
        listener: (context, state) {
          if (state is ProductVariantSaving) {
            setState(() {
              _isSaving = true;
            });
          }
          if (state is ProductVariantSaveSuccess) {
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Product variant saved successfully!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop(true); // Pop and indicate success
          } else if (state is ProductVariantSaveError) {
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
            );
          } else if (state is ProductVariantError) { // General errors not related to saving
             setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                _buildTextFormField(_nameController, 'Variant Name', isRequired: true),
                _buildTextFormField(_baseProductNameController, 'Base Product Name', isRequired: true),
                
                BlocBuilder<BrandCubit, BrandState>(
                  bloc: _brandCubit,
                  builder: (context, state) {
                    if (state is BrandLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is BrandLoaded) {
                      if (_selectedBrandId != null && !state.brands.any((b) => b.id == _selectedBrandId)) {
                        _selectedBrandId = null; 
                      }
                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Brand'),
                        value: _selectedBrandId,
                        items: state.brands.map((brand) {
                          return DropdownMenuItem<int>(
                            value: brand.id,
                            child: Text(brand.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBrandId = value;
                          });
                        },
                      );
                    } else if (state is BrandError) {
                      return Text('Error loading brands: ${state.message}');
                    }
                    return const Text('Select a Brand');
                  },
                ),

                _buildTextFormField(_upcCodeController, 'UPC Code'),
                _buildTextFormField(_packageSizeController, 'Package Size (e.g., 12oz, 500g)'),
                _buildTextFormField(_formController, 'Form (e.g., Sliced, Whole)'),
                _buildTextFormField(_containerTypeController, 'Container Type (e.g., Bottle, Can)'),
                _buildTextFormField(_preparationController, 'Preparation (e.g., Ready-to-eat)'),
                _buildTextFormField(_maturityController, 'Maturity (e.g., Ripe, Green)'),
                _buildTextFormField(_gradeController, 'Grade (e.g., Grade A, Choice)'),
                _buildTextFormField(_flavorController, 'Flavor'),
                _buildTextFormField(_scentController, 'Scent'),
                _buildTextFormField(_colorController, 'Color'),
                _buildTextFormField(_mainIngredientController, 'Main Ingredient'),
                _buildTextFormField(_spicinessLevelController, 'Spiciness Level'),
                _buildTextFormField(_caffeineContentController, 'Caffeine Content'),
                _buildTextFormField(_alcoholContentController, 'Alcohol Content'),
                _buildTextFormField(_subBrandController, 'Sub-Brand'),
                _buildTextFormField(_productLineController, 'Product Line'),

                const SizedBox(height: 10),
                const Text("Dietary & Health Attributes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildSwitchListTile('Organic', _isOrganic, (val) => setState(() => _isOrganic = val)),
                _buildSwitchListTile('Gluten-Free', _isGlutenFree, (val) => setState(() => _isGlutenFree = val)),
                _buildSwitchListTile('Non-GMO', _isNonGMO, (val) => setState(() => _isNonGMO = val)),
                _buildSwitchListTile('Vegan', _isVegan, (val) => setState(() => _isVegan = val)),
                _buildSwitchListTile('Vegetarian', _isVegetarian, (val) => setState(() => _isVegetarian = val)),
                _buildSwitchListTile('Dairy-Free', _isDairyFree, (val) => setState(() => _isDairyFree = val)),
                _buildSwitchListTile('Nut-Free', _isNutFree, (val) => setState(() => _isNutFree = val)),
                _buildSwitchListTile('Soy-Free', _isSoyFree, (val) => setState(() => _isSoyFree = val)),
                _buildSwitchListTile('Kosher', _isKosher, (val) => setState(() => _isKosher = val)),
                _buildSwitchListTile('Halal', _isHalal, (val) => setState(() => _isHalal = val)),
                _buildSwitchListTile('Sugar-Free', _isSugarFree, (val) => setState(() => _isSugarFree = val)),
                _buildSwitchListTile('Low Sodium', _isLowSodium, (val) => setState(() => _isLowSodium = val)),
                _buildSwitchListTile('Low Fat', _isLowFat, (val) => setState(() => _isLowFat = val)),
                _buildSwitchListTile('Low Carb', _isLowCarb, (val) => setState(() => _isLowCarb = val)),
                _buildSwitchListTile('High Protein', _isHighProtein, (val) => setState(() => _isHighProtein = val)),
                _buildSwitchListTile('Whole Grain', _isWholeGrain, (val) => setState(() => _isWholeGrain = val)),
                _buildSwitchListTile('No Added Sugar', _hasNoAddedSugar, (val) => setState(() => _hasNoAddedSugar = val)),
                _buildSwitchListTile('Has Artificial Sweeteners', _hasArtificialSweeteners, (val) => setState(() => _hasArtificialSweeteners = val)),
                
                const SizedBox(height: 10),
                _buildTextFormField(_allergenInfoController, 'Allergen Info (comma-separated)'),
                _buildTextFormField(_secondaryIngredientsController, 'Secondary Ingredients (comma-separated)'),
                _buildTextFormField(_customAttributesController, 'Custom Attributes (comma-separated)'),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
