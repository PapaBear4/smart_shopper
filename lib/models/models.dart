// lib/models/models.dart

/// This file serves as a barrel file for all model classes in the application.
/// Exporting all models from this central file allows for cleaner imports
/// in other parts of the application. For example, instead of importing
/// multiple model files, one can just import `package:your_app/models/models.dart`.

// Export each model file from this directory
export 'grocery_store.dart';
export 'brand.dart';
export 'price_entry.dart';
export 'shopping_item.dart';
export 'shopping_list.dart';
export 'displayable_item.dart';
export 'product_variant.dart'; // Added

// If you add more models later (e.g., 'category.dart'), add their exports here too.
// export 'category.dart';