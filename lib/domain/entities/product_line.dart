import 'package:equatable/equatable.dart';

/// Represents a product line under a main brand.
class ProductLine extends Equatable {
  final int id;
  final String name;
  final int brandId; // To associate with the parent Brand

  const ProductLine({
    required this.id,
    required this.name,
    required this.brandId,
  });

  @override
  List<Object?> get props => [id, name, brandId];
}
