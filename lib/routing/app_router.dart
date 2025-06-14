import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; 
import 'package:smart_shopper/features/stores/view/store_screen.dart';
import '../features/debug/view/debug_screen.dart'; 
import '../features/shopping_lists/view/shopping_lists_screen.dart';
import '../features/shopping_items/view/shopping_items_screen.dart';
import '../features/items_by_store/view/items_by_store_screen.dart';
import '../features/product_variants/screens/product_variants_list_screen.dart';
import '../features/product_variants/screens/product_variant_form_screen.dart';
import '../models/product_variant.dart'; // Required for casting arguments
import '../features/scan_list/presentation/pages/scan_list_page.dart'; // Added for Scan List Page
import 'dart:developer';
import 'package:flutter/foundation.dart';

// Define the router configuration
// GoRouter handles navigation throughout the app and maintains navigation state
final GoRouter appRouter = GoRouter(
  // Set the initial route when the app starts - the root path '/'
  initialLocation: '/',

  // Enable detailed GoRouter debug logs in debug mode only
  // This helps diagnose navigation issues during development
  debugLogDiagnostics: !kReleaseMode,

  // Define the app's route structure - each route shows a specific screen
  routes: <RouteBase>[
    // === ROOT ROUTE: SHOPPING LISTS SCREEN ===
    GoRoute(
      path: '/', // Root path (home screen)
      builder: (BuildContext context, GoRouterState state) {
        if (!kReleaseMode) {
          log('Router: Building root path', name: 'app_router');
        }

        // Return the screen directly - it now has its own BlocProvider
        return const ShoppingListsScreen();
      },
      // === NESTED ROUTES UNDER ROOT ===
      routes: <RouteBase>[
        // === SHOPPING ITEMS ROUTE (Child of root) ===
        GoRoute(
          // Dynamic path segment with parameter 'listId'
          // This creates URLs like /list/1, /list/42, etc.
          path: 'list/:listId',
          builder: (BuildContext context, GoRouterState state) {
            // Extract and process route parameters
            // GoRouterState.pathParameters contains all path parameters as strings
            final String? listIdParam = state.pathParameters['listId'];

            // Convert string parameter to int (required by our model)
            // Using int.tryParse which returns null if conversion fails
            final int? listId = int.tryParse(listIdParam ?? '');

            if (!kReleaseMode) {
              log('Router: Navigating to list ID: $listId (from param: $listIdParam)',
                  name: 'app_router');
            }

            // Parameter validation - ensure we have a valid list ID
            // This prevents crashes if someone manually enters an invalid URL
            if (listId == null) {
              // Show a user-friendly error screen for invalid IDs
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Invalid List ID: "$listIdParam"')),
              );
            }

            // Successfully extracted list ID - show the shopping items screen
            // ShoppingItemsScreen already has its own BlocProvider
            return ShoppingItemsScreen(listId: listId);
          },
        ),
      ],
    ),

    // === STORES MANAGEMENT ROUTE (Top-level route) ===
    GoRoute(
      path: '/stores', // Absolute path starting with /
      builder: (BuildContext context, GoRouterState state) {
        // StoreManagementScreen already has its own BlocProvider
        return const StoreManagementScreen();
      },
      // === NESTED ROUTE FOR ITEMS BY STORE ===
      routes: <RouteBase>[
        GoRoute(
          path: ':storeId/items', // Relative path: /stores/:storeId/items
          builder: (BuildContext context, GoRouterState state) {
            final String? storeIdParam = state.pathParameters['storeId'];
            final int? storeId = int.tryParse(storeIdParam ?? '');

            if (!kReleaseMode) {
              log('Router: Navigating to items for store ID: $storeId (from param: $storeIdParam)',
                  name: 'app_router');
            }

            if (storeId == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Invalid Store ID: "$storeIdParam"')),
              );
            }
            // ItemsByStoreScreen has its own BlocProvider
            return ItemsByStoreScreen(storeId: storeId);
          },
        ),
      ],
    ),
    // === DEBUG SCREEN ROUTE (Top-level route) ===
    GoRoute(
      path: '/debug',
      builder: (BuildContext context, GoRouterState state) {
        return const DebugScreen();
      },
    ),

    // === PRODUCT VARIANTS ROUTES (Top-level) ===
    GoRoute(
      path: ProductVariantsListScreen.routeName, // '/product-variants'
      builder: (BuildContext context, GoRouterState state) {
        return const ProductVariantsListScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: ProductVariantFormScreen.routeName.substring(1), // 'product-variant-form' (relative)
          name: ProductVariantFormScreen.routeName, // Optional: for named navigation if needed elsewhere
          builder: (BuildContext context, GoRouterState state) {
            final ProductVariant? productVariant = state.extra as ProductVariant?;
            return ProductVariantFormScreen(productVariant: productVariant);
          },
        ),
      ],
    ),

    // === SCAN LIST PAGE ROUTE (Top-level route) ===
    GoRoute(
      path: ScanListPage.routeName, // '/scan-list'
      builder: (BuildContext context, GoRouterState state) {
        return const ScanListPage();
      },
    ),
  ],

  // === ERROR HANDLING ===
  // Displayed when navigation fails (e.g., user enters invalid URL)
  // This ensures a good UX even when navigation errors occur
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Text('The route "${state.uri}" could not be found.'),
    ),
  ),
);
