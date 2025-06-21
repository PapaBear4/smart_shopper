//lib/models/grocery_store.dart
import 'package:equatable/equatable.dart';
import 'package:smart_shopper/domain/entities/brand.dart';

/// Represents a grocery store where items can be purchased.
class GroceryStore extends Equatable {
  final int id;
  final String name;
  final String? website;
  final String? address;
  final String? phoneNumber;
  final String? storeNumber;
  final List<Brand> brands;

  const GroceryStore({
    required this.id,
    required this.name,
    this.website,
    this.address,
    this.phoneNumber,
    this.storeNumber,
    this.brands = const [],
  });

  @override
  List<Object?> get props =>
      [id, name, website, address, phoneNumber, storeNumber, brands];
}