part of 'price_entry_cubit.dart';

abstract class PriceEntryState extends Equatable {
  const PriceEntryState();

  @override
  List<Object> get props => [];
}

class PriceEntryInitial extends PriceEntryState {}

class PriceEntryLoading extends PriceEntryState {}

class PriceEntryLoaded extends PriceEntryState {
  final List<PriceEntry> priceEntries;

  const PriceEntryLoaded(this.priceEntries);

  @override
  List<Object> get props => [priceEntries];
}

class PriceEntryError extends PriceEntryState {
  final String message;

  const PriceEntryError(this.message);

  @override
  List<Object> get props => [message];
}
