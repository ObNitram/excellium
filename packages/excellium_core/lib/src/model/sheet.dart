import 'package:meta/meta.dart';

import 'ids.dart';

/// Une feuille du classeur (un onglet), c'est-à-dire une table.
@immutable
final class Sheet {
  const Sheet({required this.id, required this.name, required this.position});

  final SheetId id;
  final String name;

  /// Rang de l'onglet, à partir de 0.
  final int position;

  Sheet copyWith({String? name, int? position}) => Sheet(
    id: id,
    name: name ?? this.name,
    position: position ?? this.position,
  );

  @override
  bool operator ==(Object other) =>
      other is Sheet &&
      other.id == id &&
      other.name == name &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, name, position);

  @override
  String toString() => 'Sheet($name, #$position)';
}
