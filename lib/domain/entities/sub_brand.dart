import 'package:equatable/equatable.dart';

/// Represents a sub-brand under a main brand.
class SubBrand extends Equatable {
  final int id;
  final String name;
  final int brandId; // To associate with the parent Brand

  const SubBrand({
    required this.id,
    required this.name,
    required this.brandId,
  });

  @override
  List<Object?> get props => [id, name, brandId];
}
