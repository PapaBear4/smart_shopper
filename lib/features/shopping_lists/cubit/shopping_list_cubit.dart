// lib/features/shopping_lists/cubit/shopping_list_cubit.dart
import 'dart:async'; // For StreamSubscription
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/models.dart'; // Barrel file
import '../../../repositories/shopping_list_repository.dart'; // Repository

part 'shopping_list_state.dart'; // Link state file

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final IShoppingListRepository _repository;
  StreamSubscription? _listSubscription; // To listen to repository stream
  bool _subscriptionActive = false;

  ShoppingListCubit({required IShoppingListRepository repository})
    : _repository = repository,
      super(ShoppingListInitial()) {
    if (!kReleaseMode) {
      log('ShoppingListCubit: Constructor called.', name: 'ShoppingListCubit');
      // Log current repository state
      log('ShoppingListCubit: Repository has ${repository.getCount()} lists', 
          name: 'ShoppingListCubit');
    }
    
    // Start with a loading state
    emit(ShoppingListLoading());
    if (!kReleaseMode) {
      log('ShoppingListCubit: Emitted initial ShoppingListLoading state', 
          name: 'ShoppingListCubit');
    }
    
    // Immediately subscribe to the repository stream
    _subscribeToLists(); 
  }

  // Subscribe to the stream from the repository
  void _subscribeToLists() {
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
    
    // Cancel any existing subscription first
    _listSubscription?.cancel();
    
    if (!kReleaseMode) {
      log('ShoppingListCubit: Attempting to listen to repository stream.', 
          name: 'ShoppingListCubit');
    }
    
    // Setup a new subscription
    try {
      _subscriptionActive = true;
      _listSubscription = _repository.getAllListsStream().listen(
        (lists) {
          if (!kReleaseMode) {
            log('ShoppingListCubit: Stream emitted ${lists.length} lists.', 
                name: 'ShoppingListCubit');
          }
          emit(ShoppingListLoaded(lists));
          if (!kReleaseMode) {
            log('ShoppingListCubit: Emitted ShoppingListLoaded with ${lists.length} lists.', 
                name: 'ShoppingListCubit');
          }
        },
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

  Future<void> addList(String name) async {
    if (name.trim().isEmpty) return;

    try {
      final newList = ShoppingList(name: name.trim());
      await _repository.addList(newList);
      
      if (!kReleaseMode) {
        log('ShoppingListCubit: Added list "$name".', 
            name: 'ShoppingListCubit');
      }
    } catch (e, s) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error adding list "$name".', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      emit(ShoppingListError("Failed to add list: $e"));
      
      // If there was an error, attempt to restore the previous state
      _resubscribeToListsAfterError();
    }
  }

  Future<void> deleteList(int id) async {
    try {
      final success = await _repository.deleteList(id);
      
      // This is now separate from the logging condition
      if (!success) {
        if (!kReleaseMode) {
          log('ShoppingListCubit: Delete operation reported no list removed with ID $id.', 
              name: 'ShoppingListCubit');
        }
        // In both debug and release, attempt to refresh the list if delete failed
        _resubscribeToListsAfterError();
      }
    } catch (e, s) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error deleting list ID $id.', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      emit(ShoppingListError("Failed to delete list: $e"));
      
      // If there was an error, attempt to restore the previous state
      _resubscribeToListsAfterError();
    }
  }

  Future<void> renameList(int id, String newName) async {
    if (newName.trim().isEmpty) return;
    
    try {
      final updatedList = ShoppingList(id: id, name: newName.trim());
      await _repository.updateList(updatedList);
      
      if (!kReleaseMode) {
        log('ShoppingListCubit: Renamed list ID $id to "$newName".', 
            name: 'ShoppingListCubit');
      }
    } catch (e, s) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Error renaming list ID $id.', 
            name: 'ShoppingListCubit', 
            error: e, 
            stackTrace: s);
      }
      emit(ShoppingListError("Failed to rename list: $e"));
      
      // If there was an error, attempt to restore the previous state
      _resubscribeToListsAfterError();
    }
  }

  // Helper method to resubscribe to lists after an error
  void _resubscribeToListsAfterError() {
    if (!_subscriptionActive) {
      if (!kReleaseMode) {
        log('ShoppingListCubit: Resubscribing after error', 
            name: 'ShoppingListCubit');
      }
      _subscribeToLists();
    }
  }

  // Manually refresh lists if needed
  Future<void> refreshLists() async {
    emit(ShoppingListLoading());
    _subscribeToLists();
  }

  // Remember to cancel the subscription when the Cubit is closed
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
