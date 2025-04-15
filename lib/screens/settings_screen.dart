import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/shopping_item_repository.dart';
import '../repositories/shopping_list_repository.dart';
import '../repositories/store_repository.dart';
import '../tools/test_data_generator.dart';

class SettingsScreen extends StatefulWidget {
  final IShoppingItemRepository itemRepository;
  final IShoppingListRepository listRepository;
  final IStoreRepository storeRepository;

  const SettingsScreen({
    super.key,
    required this.itemRepository,
    required this.listRepository,
    required this.storeRepository,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isGeneratingData = false;
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Regular app settings would go here
          
          // Debug section with divider
          const Divider(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Debug Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Generate Test Data button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isGeneratingData || _isClearing
                  ? null
                  : () => _generateTestData(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isGeneratingData
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating Data...'),
                      ],
                    )
                  : const Text('Generate Test Data'),
            ),
          ),
          
          // Clear All Data button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isGeneratingData || _isClearing
                  ? null 
                  : () => _clearAllData(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isClearing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Clearing Data...'),
                      ],
                    )
                  : const Text('Clear All Data'),
            ),
          ),
          
          // Warning text
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Warning: These actions affect your app\'s data and are intended for development purposes only.',
              style: TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTestData(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Test Data'),
        content: const Text(
          'This will add sample grocery stores, shopping lists, and items to your app. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isGeneratingData = true;
      });
      
      try {
        // Use the repositories from widget properties instead of Provider
        final generator = TestDataGenerator(
          widget.itemRepository,
          widget.listRepository,
          widget.storeRepository,
        );
        await generator.generateAllTestData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test data generated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating test data: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isGeneratingData = false;
          });
        }
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    // Show confirmation dialog with extra warning
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'WARNING: This will permanently delete ALL your shopping lists, items, and store information. This action cannot be undone. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isClearing = true;
      });
      
      try {
        // Use the repositories from widget properties instead of Provider
        final generator = TestDataGenerator(
          widget.itemRepository,
          widget.listRepository,
          widget.storeRepository,
        );
        await generator.clearAllData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isClearing = false;
          });
        }
      }
    }
  }
}