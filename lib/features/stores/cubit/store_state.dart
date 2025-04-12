part of 'store_cubit.dart'; // Link to the cubit file

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object> get props => [];
}

class StoreInitial extends StoreState {}

class StoreLoading extends StoreState {}

// State when stores are successfully loaded
class StoreLoaded extends StoreState {
  final List<GroceryStore> stores;

  const StoreLoaded(this.stores);

  @override
  List<Object> get props => [stores];
}

// State for handling errors
class StoreError extends StoreState {
  final String message;

  const StoreError(this.message);

  @override
  List<Object> get props => [message];
}