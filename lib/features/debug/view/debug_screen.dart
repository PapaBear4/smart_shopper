import 'package:flutter/material.dart';
import 'package:smart_shopper/tools/debug_utilities.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_shopper/features/product_variants/screens/product_variants_list_screen.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Options'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  try {
                    await DebugUtilities.generateTestData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test data generated successfully.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error generating test data: $e')),
                    );
                  }
                },
                child: const Text('Generate Test Data'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  try {
                    await DebugUtilities.clearAppData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App data cleared successfully.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error clearing app data: $e')),
                    );
                  }
                },
                child: const Text('Clear App Data'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.push(ProductVariantsListScreen.routeName);
                },
                child: const Text('Manage Product Variants'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
