import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_shopper/features/stores/view/store_screen.dart';
import '../features/shopping_lists/view/shopping_lists_screen.dart'; // Import your main screen
import '../features/shopping_items/view/shopping_items_screen.dart';

// Define the router configuration
final GoRouter appRouter = GoRouter(
  // Set the initial route when the app starts
  initialLocation: '/',

  // Define the list of routes
  routes: <RouteBase>[
    // Route for the main Shopping Lists screen
    GoRoute(
      path: '/', // This is the root path
      builder: (BuildContext context, GoRouterState state) {
        // When the path is '/', build and return the ShoppingListsScreen
        return const ShoppingListsScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'list/:listId', // Matches paths like /list/1, /list/42, etc.
          builder: (BuildContext context, GoRouterState state) {
            // Extract the 'listId' parameter from the path
            final String listIdString = state.pathParameters['listId'] ?? '0';
            // Convert the string parameter to an integer
            final int listId = int.tryParse(listIdString) ?? 0;

            // Return the ShoppingItemsScreen, passing the extracted ID
            return ShoppingItemsScreen(listId: listId); // <<< Ensure this line is active
          },
        ),
      ],
    ),
    GoRoute(
      path: '/stores', // Path for the store management screen
      builder: (BuildContext context, GoRouterState state) {
        return const StoreManagementScreen(); // Build the screen
      },
    ),

    // Add other top-level routes here if needed (e.g., '/settings')
  ],

  // Optional: A builder for handling routes that are not found
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Text('The route "${state.uri}" could not be found.'),
    ),
  ),
);