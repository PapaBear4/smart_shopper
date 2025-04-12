// lib/features/shopping_lists/cubit/shopping_list_cubit.dart
import 'dart:async'; // For StreamSubscription
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart'; // Barrel file
import '../../../repositories/shopping_list_repository.dart'; // Repository

part 'shopping_list_state.dart'; // Link state file

/// Cubit responsible for managing shopping list state throughout the app
/// Handles CRUD operations and maintains a stream subscription to the repository
/// for real-time updates of shopping list data
class ShoppingListCubit extends Cubit<ShoppingListState> {
  // Repository dependency - injected through constructor
  final IShoppingListRepository _repository;
  
  // Stream subscription to listen for repository data changes
  StreamSubscription? _listSubscription;
  
  // Flag to track if we have an active subscription
  bool _subscriptionActive = false;

  /// Constructor - initializes the cubit with the repository dependency
  /// Immediately sets up subscription to repository data
  ShoppingListCubit({required IShoppingListRepository repository})
    : _repository = repository,
      // Start with initial state before loading data
      super(ShoppingListInitial()) {
    // Debug logging in development builds
    if (!kReleaseMode) {
      log('ShoppingListCubit: Constructor called.', name: 'ShoppingListCubit');
      // Log current repository state
      log('ShoppingListCubit: Repository has ${repository.getCount()} lists', 
          name: 'ShoppingListCubit');
    }
    
    // First emit a loading state to show activity indicators in UI
    emit(ShoppingListLoading());
    if (!kReleaseMode) {
      log('ShoppingListCubit: Emitted initial ShoppingListLoading state', 
          name: 'ShoppingListCubit');
    }
    
    // Load initial data immediately - this ensures we have data right away
    _loadInitialData();
    
    // Then start listening for future changes
    _subscribeToLists(); 
  }

  /// Loads initial data from the repository immediately
  /// This ensures the UI has data to display as soon as possible
  Future<void> _loadInitialData() async {
    try {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Loading initial data', name: 'ShoppingListCubit');
      }
      
      // Get all lists from the repository
      final lists = await _repository.getAllLists();
      
      // Emit loaded state with the initial data
      emit(ShoppingListLoaded(lists));
      
      if (!kReleaseMode) {
        log('ShoppingListCubit: Loaded initial data with ${lists.length} lists', 
            name: 'ShoppingListCubit');
      }
    } catch (e, s) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error loading initial data', 
            name: 'ShoppingListCubit',
            error: e,
            stackTrace: s);
      }
      emit(ShoppingListError("Failed to load initial data: $e"));
    }
  }

  /// Sets up a subscription to the repository's data stream
  /// This ensures the UI automatically updates when data changes
  void _subscribeToLists() {
    // Prevent multiple subscriptions
    if (_subscriptionActive) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Subscription already active, skipping', 
            name: 'ShoppingListCubit');
      }
      return;
    }
    
    if (!kReleaseMode) {
      log('ShoppingListCubit: _subscribeToLists called.', name: 'ShoppingListCubit');
    }
    
    // Cancel any existing subscription first to prevent memory leaks
    _listSubscription?.cancel();
    
    if (!kReleaseMode) {
      log('ShoppingListCubit: Attempting to listen to repository stream.', 
          name: 'ShoppingListCubit');
    }
    
    // Setup a new subscription to the repository stream
    try {
      _subscriptionActive = true;
      _listSubscription = _repository.getAllListsStream().listen(
        // Success handler - emit new state with updated data
        (lists) {
          if (!kReleaseMode) {
            log('ShoppingListCubit: Stream emitted ${lists.length} lists.', 
                name: 'ShoppingListCubit');
          }
          // Update UI with new list data
          emit(ShoppingListLoaded(lists));
          if (!kReleaseMode) {
            log('ShoppingListCubit: Emitted ShoppingListLoaded with ${lists.length} lists.', 
                name: 'ShoppingListCubit');
          }
        },
        // Error handler - emit error state for UI to display
        onError: (error, stackTrace) {
          _subscriptionActive = false;
          if (!kReleaseMode) {
            log('ShoppingListCubit: Stream error.', 
                name: 'ShoppingListCubit', 
                error: error, 
                stackTrace: stackTrace);
          }
          emit(ShoppingListError("Failed to load lists: $error"));
        },
        // Done handler - called if stream closes (usually on app shutdown)
        onDone: () {
          _subscriptionActive = false;
          if (!kReleaseMode) {
            log('ShoppingListCubit: Stream closed (onDone).', 
                name: 'ShoppingListCubit');
          }
        },
      );
      
      if (!kReleaseMode) {
        log('ShoppingListCubit: Subscription setup complete.', 
            name: 'ShoppingListCubit');
      }
    } catch (e, s) {
      // Handle errors during subscription setup
      _subscriptionActive = false;
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error setting up stream.', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      emit(ShoppingListError("Failed to setup list subscription: $e"));
    }
  }

  /// Creates a new shopping list with the given name
  /// The repository stream will automatically update the UI after adding
  Future<void> addList(String name) async {
    // Skip empty names
    if (name.trim().isEmpty) return;

    try {
      // Create and add the new list to repository
      final newList = ShoppingList(name: name.trim());
      await _repository.addList(newList);
      
      if (!kReleaseMode) {
        log('ShoppingListCubit: Added list "$name".', 
            name: 'ShoppingListCubit');
      }
      // No need to emit state here - the repository stream will handle it
    } catch (e, s) {
      // Handle errors during add operation
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error adding list "$name".', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      // Emit error state for UI to display
      emit(ShoppingListError("Failed to add list: $e"));
      
      // Try to restore subscription if there was an error
      _resubscribeToListsAfterError();
    }
  }

  /// Deletes a shopping list by its ID
  /// The repository stream will automatically update the UI after deletion
  Future<void> deleteList(int id) async {
    try {
      // Attempt to delete the list from repository
      final success = await _repository.deleteList(id);
      
      // Check if delete operation was successful
      if (!success) {
        if (!kReleaseMode) {
          log('ShoppingListCubit: Delete operation reported no list removed with ID $id.', 
              name: 'ShoppingListCubit');
        }
        // If delete fails, try to refresh the list data
        _resubscribeToListsAfterError();
      }
      // No need to emit state here - the repository stream will handle it
    } catch (e, s) {
      // Handle errors during delete operation
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error deleting list ID $id.', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      // Emit error state for UI to display
      emit(ShoppingListError("Failed to delete list: $e"));
      
      // Try to restore subscription if there was an error
      _resubscribeToListsAfterError();
    }
  }

  /// Updates the name of an existing shopping list
  /// The repository stream will automatically update the UI after renaming
  Future<void> renameList(int id, String newName) async {
    // Skip empty names
    if (newName.trim().isEmpty) return;
    
    try {
      // Create updated list object with same ID but new name
      final updatedList = ShoppingList(id: id, name: newName.trim());
      await _repository.updateList(updatedList);
      
      if (!kReleaseMode) {
        log('ShoppingListCubit: Renamed list ID $id to "$newName".', 
            name: 'ShoppingListCubit');
      }
      // No need to emit state here - the repository stream will handle it
    } catch (e, s) {
      // Handle errors during update operation
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error renaming list ID $id.', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      // Emit error state for UI to display
      emit(ShoppingListError("Failed to rename list: $e"));
      
      // Try to restore subscription if there was an error
      _resubscribeToListsAfterError();
    }
  }

  /// Helper method to reestablish repository subscription after an error
  /// Ensures UI continues to get updates even after an operation fails
  void _resubscribeToListsAfterError() {
    if (!_subscriptionActive) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Resubscribing after error', 
            name: 'ShoppingListCubit');
      }
      _subscribeToLists();
    }
  }

  /// Manual refresh method - forces a reload of data from repository
  /// Useful for pull-to-refresh functionality or after network reconnection
  Future<void> refreshLists() async {
    emit(ShoppingListLoading());
    _subscribeToLists();
  }

  /// Cleanup method called when cubit is no longer needed
  /// Ensures we don't have memory leaks from lingering subscriptions
  @override
  Future<void> close() {
    if (!kReleaseMode) {
      log('ShoppingListCubit: close() called, cancelling subscription.', 
          name: 'ShoppingListCubit');
    }
    _subscriptionActive = false;
    _listSubscription?.cancel();
    return super.close();
  }
}
