import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart';
import '../objectbox.g.dart';

/// Defines the interface for price entry data operations.
/// This abstraction allows for easy testing and dependency injection.
abstract class IPriceEntryRepository {
  /// Returns a stream of all price entries, sorted by date descending.
  /// The stream emits a new list whenever the data changes.
  Stream<List<PriceEntry>> getPriceEntriesStream();

  /// Fetches all price entries from the database once.
  Future<List<PriceEntry>> getAllPriceEntries();

  /// Adds a new price entry to the database.
  /// Returns the ID of the newly created price entry.
  Future<int> addPriceEntry(PriceEntry priceEntry);

  /// Updates an existing price entry in the database.
  Future<void> updatePriceEntry(PriceEntry priceEntry);

  /// Deletes a price entry from the database by its ID.
  /// Returns true if the deletion was successful.
  Future<bool> deletePriceEntry(int id);

  // Potential future methods for more specific queries.
  // These would allow fetching price data filtered by product, store, etc.
  // Example: Future<List<PriceEntry>> getPriceEntriesForProduct(int productVariantId);
  // Example: Future<List<PriceEntry>> getPriceEntriesForStore(int storeId);
}

/// Concrete implementation of [IPriceEntryRepository] using ObjectBox.
/// Handles all CRUD operations for the [PriceEntry] entity.
class PriceEntryRepository implements IPriceEntryRepository {
  final ObjectBoxHelper _objectBoxHelper;
  late final Box<PriceEntry> _priceEntryBox;

  /// Constructor for PriceEntryRepository.
  /// Requires an instance of [ObjectBoxHelper] to initialize the box.
  PriceEntryRepository(this._objectBoxHelper) {
    _priceEntryBox = _objectBoxHelper.priceEntryBox;
  }

  @override
  Stream<List<PriceEntry>> getPriceEntriesStream() {
    // Create a query for all PriceEntry objects, ordered by date descending.
    // .watch() creates a stream that automatically updates with changes.
    final query = _priceEntryBox
        .query()
        .order(PriceEntry_.date, flags: Order.descending)
        .watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<PriceEntry>> getAllPriceEntries() async {
    // .getAll() retrieves all objects from the box.
    final entries = _priceEntryBox.getAll();
    // Sort the list in-place by date, newest first.
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<int> addPriceEntry(PriceEntry priceEntry) async {
    // .put() inserts or updates an object and returns its ID.
    return _priceEntryBox.put(priceEntry);
  }

  @override
  Future<void> updatePriceEntry(PriceEntry priceEntry) async {
    // .put() is also used for updates if the object has a non-zero ID.
    _priceEntryBox.put(priceEntry);
  }

  @override
  Future<bool> deletePriceEntry(int id) async {
    // .remove() deletes an object by its ID and returns true on success.
    return _priceEntryBox.remove(id);
  }
}
