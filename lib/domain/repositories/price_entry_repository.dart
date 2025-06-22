import 'package:smart_shopper/domain/entities/price_entry.dart';

/// Repository for managing price entries.
abstract class PriceEntryRepository {
  /// Retrieves all price entries.
  Future<List<PriceEntry>> getAll();

  /// Retrieves a single price entry by its ID.
  Future<PriceEntry?> getById(int id);

  /// Saves a price entry (creates if new, updates if exists).
  Future<void> save(PriceEntry entry);

  /// Deletes a price entry by its ID.
  Future<void> delete(int id);

  /// Watches for changes to all price entries.
  Stream<List<PriceEntry>> watchAll();
}
