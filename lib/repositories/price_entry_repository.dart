import 'dart:async';
import '../models/models.dart';
import '../objectbox_helper.dart'; // Changed from objectbox.dart
import '../objectbox.g.dart';

abstract class IPriceEntryRepository {
  Stream<List<PriceEntry>> getPriceEntriesStream();
  Future<List<PriceEntry>> getAllPriceEntries();
  Future<int> addPriceEntry(PriceEntry priceEntry);
  Future<void> updatePriceEntry(PriceEntry priceEntry);
  Future<bool> deletePriceEntry(int id);
  // Add methods for specific queries based on user feedback, e.g.:
  // Future<List<PriceEntry>> getPriceEntriesForItem(String canonicalItemName);
  // Future<List<PriceEntry>> getPriceEntriesForStore(int storeId);
  // Future<List<PriceEntry>> getPriceEntriesForBrand(int brandId);
}

class PriceEntryRepository implements IPriceEntryRepository {
  final ObjectBoxHelper _objectBoxHelper; // Changed type
  late final Box<PriceEntry> _priceEntryBox;

  PriceEntryRepository(this._objectBoxHelper) { // Changed parameter type
    _priceEntryBox = _objectBoxHelper.priceEntryBox; // Changed to use helper
  }

  @override
  Stream<List<PriceEntry>> getPriceEntriesStream() {
    // Default sort by date, newest first. Adjust as needed.
    final query = _priceEntryBox.query().order(PriceEntry_.date, flags: Order.descending).watch(triggerImmediately: true);
    return query.map((query) => query.find());
  }

  @override
  Future<List<PriceEntry>> getAllPriceEntries() async {
    final entries = _priceEntryBox.getAll();
    // Default sort by date, newest first.
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<int> addPriceEntry(PriceEntry priceEntry) async {
    return _priceEntryBox.put(priceEntry);
  }

  @override
  Future<void> updatePriceEntry(PriceEntry priceEntry) async {
    _priceEntryBox.put(priceEntry);
  }

  @override
  Future<bool> deletePriceEntry(int id) async {
    return _priceEntryBox.remove(id);
  }
}
