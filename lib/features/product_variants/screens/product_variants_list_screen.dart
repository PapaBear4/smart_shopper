import 'dart:async'; // Import for Timer

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Added GoRouter import
import '../../../service_locator.dart'; // For getIt
import '../cubit/product_variant_cubit.dart';
import '../../../models/models.dart'; // For ProductVariant and Brand
import '../../../common_widgets/loading_indicator.dart';
import '../../../common_widgets/empty_list_widget.dart';
import '../../../common_widgets/error_display.dart';
import './product_variant_form_screen.dart'; // Import the form screen
import '../../../features/brands/cubit/brand_cubit.dart'; // Import BrandCubit

class ProductVariantsListScreen extends StatelessWidget {
  const ProductVariantsListScreen({super.key});

  static const String routeName = '/product-variants';

  @override
  Widget build(BuildContext context) {
    // Provide ProductVariantCubit at this level
    return BlocProvider(
      create: (context) => getIt<ProductVariantCubit>()..loadProductVariants(),
      child: const _ProductVariantsView(), // _ProductVariantsView will build the Scaffold and provide BrandCubit
    );
  }
}

class _ProductVariantsView extends StatefulWidget {
  const _ProductVariantsView();

  @override
  State<_ProductVariantsView> createState() => _ProductVariantsViewState();
}

class _ProductVariantsViewState extends State<_ProductVariantsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  int? _selectedBrandIdFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ProductVariantCubit>().searchProductVariants(_searchController.text, brandId: _selectedBrandIdFilter);
    });
  }

  void _applyFilter({int? brandId}) {
    setState(() {
      _selectedBrandIdFilter = brandId;
    });
    // Trigger search with the new filter
    context.read<ProductVariantCubit>().searchProductVariants(_searchController.text, brandId: _selectedBrandIdFilter);
  }

  void _clearFilters() {
    setState(() {
      _selectedBrandIdFilter = null;
    });
    _searchController.clear(); // This will trigger _onSearchChanged with empty text and null brandId
    // context.read<ProductVariantCubit>().loadProductVariants(); // Or directly load all
  }

  Future<void> _showFilterDialog(BuildContext dialogParentContext) async {
    // Using a temporary variable to hold selection within the dialog before applying
    int? dialogSelectedBrandId = _selectedBrandIdFilter;

    await showDialog(
      context: dialogParentContext, // Important: use the context passed to the method
      builder: (BuildContext innerDialogContext) {
        // Use a StatefulBuilder to manage the state of the DropdownButtonFormField within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Brand'),
              content: BlocBuilder<BrandCubit, BrandState>(
                // BrandCubit is provided by the MultiBlocProvider wrapping this widget tree
                builder: (brandContext, brandState) {
                  if (brandState is BrandLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (brandState is BrandLoaded) {
                    return DropdownButtonFormField<int?>(
                      value: dialogSelectedBrandId,
                      hint: const Text('All Brands'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Brands'),
                        ),
                        ...brandState.brands.map((brand) {
                          return DropdownMenuItem<int?>(
                            value: brand.id,
                            child: Text(brand.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          dialogSelectedBrandId = value;
                        });
                      },
                    );
                  }
                  if (brandState is BrandError) {
                    return Text('Error loading brands: ${brandState.message}');
                  }
                  return const Text('Could not load brand filter options.');
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Clear Filters'),
                  onPressed: () {
                    _clearFilters();
                    Navigator.of(innerDialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(innerDialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    _applyFilter(brandId: dialogSelectedBrandId);
                    Navigator.of(innerDialogContext).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provide BrandCubit here, specific to _ProductVariantsView and its children (like the dialog)
    return BlocProvider(
      create: (brandContext) => getIt<BrandCubit>(), // BrandCubit loads its data on creation
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Variants'),
          actions: [
            // The search IconButton can be removed if the search bar is always visible
            // IconButton(
            //   icon: const Icon(Icons.search),
            //   onPressed: () {
            //     // TODO: Implement search UI toggle or navigation if search bar is not always visible
            //   },
            // ),
            Builder( // Use Builder to get a context that is descendant of BrandCubit's BlocProvider
              builder: (appBarContext) {
                return IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog(appBarContext); // Pass the correct context
                  },
                );
              }
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration( // Removed const
                  labelText: 'Search Variants',
                  hintText: 'Enter name, base name, etc.',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear(); // Listener will trigger search
                    },
                  ),
                ),
                // onChanged is handled by listener
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductVariantCubit, ProductVariantState>(
                builder: (context, state) {
                  if (state is ProductVariantLoading) {
                    return const LoadingIndicator();
                  } else if (state is ProductVariantLoaded) {
                    if (state.productVariants.isEmpty) {
                      final bool filtersActive = _selectedBrandIdFilter != null || _searchController.text.isNotEmpty;
                      return EmptyListWidget(message: filtersActive ? 'No variants match your criteria.' : 'No product variants found. Add some!');
                    }
                    return ListView.builder(
                      itemCount: state.productVariants.length,
                      itemBuilder: (context, index) {
                        final variant = state.productVariants[index];
                        return Dismissible(
                          key: Key(variant.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Delete"),
                                  content: Text("Are you sure you want to delete ${variant.name}?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text("CANCEL"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text("DELETE"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            context.read<ProductVariantCubit>().deleteProductVariant(variant.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${variant.name} deleted')),
                            );
                          },
                          child: ListTile(
                            title: Text(variant.name),
                            subtitle: Text(
                              '${variant.baseProductName}'
                              '${variant.brand.target?.name != null ? " - ${variant.brand.target!.name}" : ""}' // Display brand name
                              '${variant.packageSize != null && variant.packageSize!.isNotEmpty ? ' - ${variant.packageSize}' : ''}'
                            ),
                            onTap: () {
                              // Changed to use GoRouter.pushNamed with extra for arguments
                              GoRouter.of(context).pushNamed(ProductVariantFormScreen.routeName, extra: variant);
                            },
                          ),
                        );
                      },
                    );
                  } else if (state is ProductVariantError) {
                    return ErrorDisplay(message: state.message);
                  }
                  return const SizedBox.shrink(); // Should not happen
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Ensure the context used for navigation has access to GoRouter (usually true if MaterialApp.router is used)
            // Changed to use GoRouter.pushNamed for consistency, passing null as extra for a new variant
            GoRouter.of(context).pushNamed(ProductVariantFormScreen.routeName, extra: null);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}