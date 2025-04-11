import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/shopping_lists/view/shopping_lists_screen.dart'; // Import your main screen

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
      // We can define nested routes later for list details, items etc.
      // Example for later:
      /*
      routes: <RouteBase>[
        GoRoute(
          path: 'list/:listId', // Path parameter for list ID e.g., /list/1
          builder: (BuildContext context, GoRouterState state) {
            // Extract the listId from the path parameters
            final String listIdString = state.pathParameters['listId'] ?? '0';
            final int listId = int.tryParse(listIdString) ?? 0;
            // Return the screen for viewing items in a specific list
            // return ShoppingItemsScreen(listId: listId); // You'll create this screen later
          },
        ),
      ],
      */
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