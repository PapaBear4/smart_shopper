import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'objectbox_helper.dart'; // Import the ObjectBox helper class
import 'service_locator.dart'; // Import the GetIt setup file
import 'presentation/routing/app_router.dart'; // Import the router config

/// Entry point of the application
/// Sets up dependencies and initializes the app
Future<void> main() async {
  // IMPORTANT: Ensure Flutter bindings are initialized before using plugins.
  // This is required before using any platform channels or plugins
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load .env file

  // OBJECTBOX SETUP
  // Initialize the ObjectBox database instance
  // ObjectBox is a NoSQL database used for local data persistence
  final objectboxInstance = await ObjectBoxHelper.create();

  // Set up dependency injection using GetIt service locator
  // This makes services and repositories available throughout the app
  setupLocator(objectboxInstance);

  // RUN THE APP
  // Launch the root widget of the application
  runApp(const SmartShopperApp());
}

/// Root widget of the application
/// Configures the overall app theme and navigation
class SmartShopperApp extends StatelessWidget {
  const SmartShopperApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with BlocProvider to make ShoppingListCubit available throughout the app
    // This ensures shopping lists data is loaded immediately when the app starts
    return MaterialApp.router(
      title: 'Smart Shopper App', // App title shown in task switchers
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Enables the latest Material Design features
        brightness: Brightness.light, // Sets light mode as default
      ),
      routerConfig:
          appRouter, // Uses the GoRouter configuration from app_router.dart
    );
  }
}
