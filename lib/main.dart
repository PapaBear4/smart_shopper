import 'package:flutter/material.dart';
import 'objectbox.dart'; // Import the ObjectBox helper class
import 'service_locator.dart'; // Import the GetIt setup file

Future<void> main() async {
  // IMPORTANT: Ensure Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create the ObjectBox instance (as before)
  final objectboxInstance = await ObjectBox.create();

  // 2. Call the setup function and pass the ObjectBox instance to register it
  setupLocator(objectboxInstance);

  // 3. Now run the app
  runApp(const MyApp());
}

// --- Keep the rest of your MyApp widget code ---
// Example placeholder:
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Later, we'll wrap this with BlocProvider, RepositoryProvider etc.
    return MaterialApp(
      title: 'Shopping List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Optional: Use Material 3 design
      ),
      home: const ExampleHomeScreen(),
    );
  }
}

// --- Example Screen Demonstrating GetIt Usage ---
class ExampleHomeScreen extends StatelessWidget {
  const ExampleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ObjectBox instance anywhere using GetIt:
    final objectbox = getIt<ObjectBox>();

    // Now you can use the objectbox instance, e.g., access its boxes
    int listCount = objectbox.shoppingListBox.count(); // Example: Get count of lists

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List (GetIt)')),
      body: Center(
        child: Text(
          'ObjectBox is ready via GetIt!\nNumber of shopping lists: $listCount',
        ),
      ),
      // We'll add a FloatingActionButton later to add lists
    );
  }
}
