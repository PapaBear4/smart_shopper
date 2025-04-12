import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_shopper/features/shopping_lists/cubit/shopping_list_cubit.dart';
import 'package:smart_shopper/features/stores/view/store_screen.dart';
import 'package:smart_shopper/service_locator.dart';
import '../features/shopping_lists/view/shopping_lists_screen.dart';
import '../features/shopping_items/view/shopping_items_screen.dart';
import '../repositories/shopping_list_repository.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';

// Define the router configuration
final GoRouter appRouter = GoRouter(
  // Set the initial route when the app starts
  initialLocation: '/',
  
  // Optional logging for debugging navigation issues
  debugLogDiagnostics: !kReleaseMode,

  // Define the list of routes
  routes: <RouteBase>[
    // Route for the main Shopping Lists screen
    GoRoute(
      path: '/', // This is the root path
      builder: (BuildContext context, GoRouterState state) {
        if (!kReleaseMode) {
          log('Router: Building root path with BlocProvider', name: 'app_router');
        }
        
        // Get repository from service locator
        final repo = getIt<IShoppingListRepository>();
        
        if (!kReleaseMode) {
          log('Router: Repository instance obtained from GetIt', name: 'app_router');
        }
        
        // Wrap the screen with BlocProvider
        return BlocProvider(
          // Create the Cubit with the repository
          create: (_) => ShoppingListCubit(repository: repo),
          // Return the actual screen as the child
          child: const ShoppingListsScreen(),
        );
      },
      routes: <RouteBase>[
        // Nested route for viewing items within a specific list
        GoRoute(
          path: 'list/:listId', // Matches paths like /list/1, /list/42, etc.
          builder: (BuildContext context, GoRouterState state) {
            // Extract the 'listId' parameter from the path
            final String? listIdParam = state.pathParameters['listId'];
            
            // Parse as integer since the model uses int IDs
            final int? listId = int.tryParse(listIdParam ?? '');
            
            if (!kReleaseMode) {
              log('Router: Navigating to list ID: $listId (from param: $listIdParam)', 
                  name: 'app_router');
            }

            // Ensure listId is valid (not null after parsing)
            if (listId == null) {
              // Show an error if ID is invalid
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Invalid List ID: "$listIdParam"')),
              );
            }

            // Return the ShoppingItemsScreen with the parsed integer ID
            return ShoppingItemsScreen(listId: listId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/stores', // Path for the store management screen
      builder: (BuildContext context, GoRouterState state) {
        // Return store management screen
        return const StoreManagementScreen();
      },
    ),
  ],

  // Optional: A builder for handling routes that are not found
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Text('The route "${state.uri}" could not be found.'),
    ),
  ),
);
