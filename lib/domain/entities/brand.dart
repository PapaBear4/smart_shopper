import 'package:equatable/equatable.dart';

/// Represents a brand of a product.
/// This is a pure domain entity, independent of any data source.
class Brand extends Equatable {
  final int id;
  final String name;

  const Brand({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
