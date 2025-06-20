// Import necessary libraries and files.
import 'package:smart_shopper/objectbox.g.dart'; // ObjectBox generated file for queries.
import '../models/models.dart'; // Barrel file for data models.
import '../objectbox_helper.dart'; // Helper class for ObjectBox initialization and access.
import 'dart:developer'; // For logging, typically used during development.
import 'package:flutter/foundation.dart'; // For checking build mode (e.g., kReleaseMode).
import 'dart:async'; // For asynchronous programming, especially StreamController.

/// Abstract interface for the shopping list repository.
///
/// Defines a contract for data operations related to [ShoppingList] entities.
/// Using an interface allows for easier testing and dependency injection, as the
/// concrete implementation can be swapped with a mock version.
abstract class IShoppingListRepository {
  /// Retrieves a reactive stream of all shopping lists.
  /// The stream will automatically emit a new list of [ShoppingList] whenever data changes.
  Stream<List<ShoppingList>> getAllListsStream();

  /// Retrieves a one-time list of all shopping lists as a [Future].
  /// This is useful when you need the data once and don't need to listen for changes.
  Future<List<ShoppingList>> getAllLists();

  /// Retrieves a single shopping list by its unique ID.
  /// Returns `null` if no list is found with the given [id].
  Future<ShoppingList?> getListById(int id);

  /// Adds a new [ShoppingList] to the database.
  /// Returns the ID assigned to the new list.
  Future<int> addList(ShoppingList list);

  /// Deletes a shopping list from the database by its ID.
  /// Returns `true` if the deletion was successful, `false` otherwise.
  Future<bool> deleteList(int id);

  /// Updates an existing shopping list (e.g., for renaming).
  Future<void> updateList(ShoppingList list);

  /// Returns the total number of shopping lists in the database.
  /// Useful for debugging or displaying statistics.
  int getCount();
}

/// Concrete implementation of [IShoppingListRepository] using ObjectBox as the database.
class ShoppingListRepository implements IShoppingListRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<ShoppingList> _listBox;
  bool _isReady = false; // Flag to track if the repository is properly initialized.

  /// Constructor for the repository.
  ///
  /// Takes an [ObjectBoxHelper] to establish a connection with the database.
  /// It initializes the [_listBox] and sets the [_isReady] flag.
  ShoppingListRepository(this._objectBoxHelper) {
    try {
      _listBox = _objectBoxHelper.shoppingListBox;
      _isReady = true;

      if (!kReleaseMode) {
        log('ShoppingListRepository: Initialized with box count: ${_listBox.count()}', name: 'ShoppingListRepository');
      }
      _getInitialLists(); // "Warm up" the repository with an initial data fetch.
    } catch (e, s) {
      _isReady = false;
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error initializing repository', name: 'ShoppingListRepository', error: e, stackTrace: s);
      }
    }
  }
  
  /// Returns the current count of lists in the box.
  @override
  int getCount() {
    if (!_isReady) return 0;
    try {
      return _listBox.count();
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error getting count', name: 'ShoppingListRepository', error: e);
      }
      return 0;
    }
  }
  
  /// Private helper to perform the initial fetch of lists.
  List<ShoppingList> _getInitialLists() {
    if (!_isReady) return [];
    try {
      final lists = _listBox.getAll();
      if (!kReleaseMode) {
        log('ShoppingListRepository: Initial query found ${lists.length} lists', name: 'ShoppingListRepository');
      }
      return lists;
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error getting initial lists', name: 'ShoppingListRepository', error: e);
      }
      return [];
    }
  }

  /// Provides a stream of all shopping lists.
  @override
  Stream<List<ShoppingList>> getAllListsStream() {
    if (!kReleaseMode) {
      log('ShoppingListRepository: Creating lists stream', name: 'ShoppingListRepository');
    }
    
    // Using a StreamController for more fine-grained control over the stream.
    final controller = StreamController<List<ShoppingList>>();
    
    if (!_isReady) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Box not ready, emitting empty list', name: 'ShoppingListRepository');
      }
      controller.add([]);
    } else {
      try {
        // Add the initial data to the stream immediately.
        controller.add(_getInitialLists());
        
        // Set up the ObjectBox watcher to listen for database changes.
        final subscription = _listBox.query().watch(triggerImmediately: true).listen((query) {
          try {
            final lists = query.find(); 
            if (!kReleaseMode) {
              log('ShoppingListRepository: Stream emitting ${lists.length} lists', name: 'ShoppingListRepository');
            }
            if (!controller.isClosed) {
              controller.add(lists);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        });
        
        // Clean up the subscription when the listener is cancelled.
        controller.onCancel = () {
          subscription.cancel();
        };
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }
    
    return controller.stream;
  }

  /// Fetches all shopping lists as a one-time operation.
  @override
  Future<List<ShoppingList>> getAllLists() async {
    if (!_isReady) return [];
    try {
      return _listBox.getAll();
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error in getAllLists', name: 'ShoppingListRepository', error: e);
      }
      return [];
    }
  }

  /// Fetches a single shopping list by its ID.
  @override
  Future<ShoppingList?> getListById(int id) async {
    if (!_isReady) return null;
    try {
      return _listBox.get(id);
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error in getListById for id: $id', name: 'ShoppingListRepository', error: e);
      }
      return null;
    }
  }

  /// Adds a new list to the database.
  @override
  Future<int> addList(ShoppingList list) async {
    if (!_isReady) {
      throw StateError('Repository not initialized properly');
    }
    
    try {
      // `put` inserts the new object and returns its ID.
      final id = _listBox.put(list);
      if (!kReleaseMode) {
        log('ShoppingListRepository: Added list "${list.name}" with ID $id', name: 'ShoppingListRepository');
      }
      return id;
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error adding list: $e', name: 'ShoppingListRepository');
      }
      rethrow; // Re-throw to allow the calling layer (Cubit) to handle the error.
    }
  }

  /// Deletes a list from the database.
  @override
  Future<bool> deleteList(int id) async {
    if (!_isReady) return false;
    
    try {
      // `remove` returns true if an object with the given ID was found and removed.
      final result = _listBox.remove(id);
      if (!kReleaseMode) {
        log('ShoppingListRepository: Deleted list ID $id, success: $result', name: 'ShoppingListRepository');
      }
      return result;
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error deleting list: $e', name: 'ShoppingListRepository');
      }
      return false;
    }
  }

  /// Updates an existing list in the database.
  @override
  Future<void> updateList(ShoppingList list) async {
    if (!_isReady) {
      throw StateError('Repository not initialized properly');
    }
    
    try {
      // `put` also updates an object if its ID already exists in the box.
      _listBox.put(list);
      if (!kReleaseMode) {
        log('ShoppingListRepository: Updated list ID ${list.id}', name: 'ShoppingListRepository');
      }
    } catch (e) {
      if (!kReleaseMode) {
        log('ShoppingListRepository: Error updating list: $e', name: 'ShoppingListRepository');
      }
      rethrow;
    }
  }
}
