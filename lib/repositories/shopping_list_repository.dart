import 'package:smart_shopper/objectbox.g.dart';
import '../models/models.dart'; // Uses the barrel file
import '../objectbox_helper.dart'; // Changed from objectbox.dart
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'dart:async'; // Import for StreamController

// Define an interface (abstract class) for testability/mocking
abstract class IShoppingListRepository {
  Stream<List<ShoppingList>> getAllListsStream(); // Get lists reactively
  Future<List<ShoppingList>> getAllLists(); // Add this non-stream method
  Future<int> addList(ShoppingList list);
  Future<bool> deleteList(int id);
  Future<void> updateList(ShoppingList list); // For renaming
  int getCount(); // Add this to interface for consistency
}

// Concrete implementation using ObjectBox
class ShoppingListRepository implements IShoppingListRepository {
  final ObjectBoxHelper _objectBoxHelper; // Changed type
  late final Box<ShoppingList> _listBox;
  // Track if the box has been initialized properly
  bool _isReady = false;

  ShoppingListRepository(this._objectBoxHelper) { // Changed parameter type
    try {
      _listBox = _objectBoxHelper.shoppingListBox; // Changed to use helper
      _isReady = true;
      
      if (!kReleaseMode) {
        log('ShoppingListRepository: Initialized with box count: ${_listBox.count()}', 
            name: 'ShoppingListRepository');
      }
      
      // Perform an initial query to "warm up" the repository
      _getInitialLists();
    } catch (e, s) {
      _isReady = false;
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error initializing repository', 
            name: 'ShoppingListRepository', error: e, stackTrace: s);
      }
    }
  }
  
  // Method to check the count (used for debugging)
  @override
  int getCount() {
    if (!_isReady) return 0;
    
    try {
      return _listBox.count();
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error getting count', 
            name: 'ShoppingListRepository', error: e);
      }
      return 0;
    }
  }
  
  // Private helper to query lists initially
  List<ShoppingList> _getInitialLists() {
    if (!_isReady) return [];
    
    try {
      final lists = _listBox.getAll();
      if (!kReleaseMode) {
        log('ShoppingListRepository: Initial query found ${lists.length} lists', 
            name: 'ShoppingListRepository');
      }
      return lists;
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error getting initial lists', 
            name: 'ShoppingListRepository', error: e);
      }
      return [];
    }
  }

  @override
  Stream<List<ShoppingList>> getAllListsStream() {
    if (!kReleaseMode) {
      log('ShoppingListRepository: Creating lists stream',
          name: 'ShoppingListRepository');
    }
    
    // Create a StreamController for more controlled emission
    final controller = StreamController<List<ShoppingList>>();
    
    // Handle the initial emission
    if (!_isReady) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Box not ready, emitting empty list',
            name: 'ShoppingListRepository');
      }
      controller.add([]); // Emit empty list if not ready
    } else {
      try {
        // Safely get initial data
        final initialLists = _getInitialLists();
        controller.add(initialLists);
        
        if (!kReleaseMode) {
          log('ShoppingListRepository: Initial stream emission with ${initialLists.length} lists',
              name: 'ShoppingListRepository');
        }
        
        // Try to set up the watcher safely
        try {
          // Create a query builder
          final queryBuilder = _listBox.query(); // No build() here yet
          
          // Watch the query builder for changes
          final subscription = queryBuilder.watch(triggerImmediately: true).listen((query) {
            if (!kReleaseMode) {
              log('ShoppingListRepository: Query change detected or initial trigger',
                  name: 'ShoppingListRepository');
            }
            
            try {
              // Find the results from the latest query state
              final lists = query.find(); 
              if (!kReleaseMode) {
                log('ShoppingListRepository: Stream emitting ${lists.length} lists',
                    name: 'ShoppingListRepository');
              }
              if (!controller.isClosed) {
                controller.add(lists);
              }
            } catch (e) {
              if (!kReleaseMode) {
                log('ShoppingListRepository: Error finding lists from query event',
                    name: 'ShoppingListRepository', error: e);
              }
              // Handle error properly in both release and debug builds
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          });
          
          // Clean up when the stream is done
          controller.onCancel = () {
            subscription.cancel();
            // No need to close the query explicitly here, cancelling the subscription handles it.
          };
        } catch (e) {
          if (!kReleaseMode) {
            log('ShoppingListRepository: Error setting up watcher',
                name: 'ShoppingListRepository', error: e);
          }
          // Keep the controller alive even if watcher setup fails
          // We've already added the initial list
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      } catch (e) {
        if (!kReleaseMode) {
          log('ShoppingListRepository: Error during stream setup',
              name: 'ShoppingListRepository', error: e);
        }
        controller.add([]);
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }
    
    return controller.stream;
  }

  /// Gets all shopping lists as a Future
  /// This provides immediate access to data without stream subscription
  @override
  Future<List<ShoppingList>> getAllLists() async {
    if (!_isReady) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Cannot get lists, box not ready', 
            name: 'ShoppingListRepository');
      }
      return [];
    }
    
    try {
      final lists = _listBox.getAll();
      if (!kReleaseMode) {
        log('ShoppingListRepository: Retrieved ${lists.length} lists', 
            name: 'ShoppingListRepository');
      }
      return lists;
    } catch (e, s) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error getting lists', 
            name: 'ShoppingListRepository', error: e, stackTrace: s);
      }
      return [];
    }
  }

  @override
  Future<int> addList(ShoppingList list) async {
    if (!_isReady) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Cannot add list, box not ready', 
            name: 'ShoppingListRepository');
      }
      throw StateError('Repository not initialized properly');
    }
    
    try {
      final id = _listBox.put(list);
      if (!kReleaseMode) {
        log('ShoppingListRepository: Added list "${list.name}" with ID $id',
            name: 'ShoppingListRepository');
      }
      return id;
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error adding list: $e',
            name: 'ShoppingListRepository');
      }
      rethrow; // Re-throw the error so the Cubit can catch it
    }
  }

  @override
  Future<bool> deleteList(int id) async {
    if (!_isReady) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Cannot delete list, box not ready', 
            name: 'ShoppingListRepository');
      }
      return false;
    }
    
    try {
      // remove() returns true if an object was removed
      final result = _listBox.remove(id);
      if (!kReleaseMode) {
        log('ShoppingListRepository: Deleted list ID $id, success: $result',
            name: 'ShoppingListRepository');
      }
      return result;
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error deleting list: $e',
            name: 'ShoppingListRepository');
      }
      return false;
    }
  }

  @override
  Future<void> updateList(ShoppingList list) async {
    if (!_isReady) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Cannot update list, box not ready', 
            name: 'ShoppingListRepository');
      }
      throw StateError('Repository not initialized properly');
    }
    
    try {
      // put() also updates if the object ID already exists
      _listBox.put(list);
      if (!kReleaseMode) {
        log('ShoppingListRepository: Updated list ID ${list.id}',
            name: 'ShoppingListRepository');
      }
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error updating list: $e',
            name: 'ShoppingListRepository');
      }
      rethrow;
    }
  }
}
