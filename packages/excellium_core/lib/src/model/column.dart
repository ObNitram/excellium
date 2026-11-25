import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'ids.dart';

/// Les types de colonne proposés à l'utilisateur.
enum ColumnType {
  text,
  number,
  percent,
  date,
  duration,
  singleCategory,
  multiCategory,
  boolean,
  reference,
}

/// Cardinalité d'une colonne de référence, vue depuis la cellule.
enum Cardinality {
  /// Relation 1–n : chaque cellule pointe vers une seule ligne.
  one,

  /// Relation n–n : chaque cellule peut pointer vers plusieurs lignes.
  many,
}

/// Paramètres d'une colonne de type [ColumnType.reference].
@immutable
final class ReferenceConfig {
  const ReferenceConfig({
    this.targetSheetId,
    this.cardinality = Cardinality.one,
    this.searchColumnIds = const [],
  });

  /// Feuille visée ; `null` tant que la relation n'est pas paramétrée.
  final SheetId? targetSheetId;
  final Cardinality cardinality;

  /// Colonnes de la feuille visée prises en compte par la recherche.
  final List<ColumnId> searchColumnIds;

  ReferenceConfig copyWith({
    SheetId? targetSheetId,
    Cardinality? cardinality,
    List<ColumnId>? searchColumnIds,
  }) => ReferenceConfig(
    targetSheetId: targetSheetId ?? this.targetSheetId,
    cardinality: cardinality ?? this.cardinality,
    searchColumnIds: searchColumnIds ?? this.searchColumnIds,
  );

  @override
  bool operator ==(Object other) =>
      other is ReferenceConfig &&
      other.targetSheetId == targetSheetId &&
      other.cardinality == cardinality &&
      const ListEquality<ColumnId>().equals(
        other.searchColumnIds,
        searchColumnIds,
      );

  @override
  int get hashCode => Object.hash(
    targetSheetId,
    cardinality,
    const ListEquality<ColumnId>().hash(searchColumnIds),
  );
}

/// Définition d'une colonne d'une feuille.
///
/// Nommée `ColumnDef` pour ne pas entrer en conflit avec le widget `Column`
/// de Flutter.
@immutable
final class ColumnDef {
  const ColumnDef({
    required this.id,
    required this.sheetId,
    required this.position,
    this.name = '',
    this.type = ColumnType.text,
    this.width = defaultWidth,
    this.reference,
  });

  static const double defaultWidth = 120;
  static const double minWidth = 48;
  static const double maxWidth = 480;

  final ColumnId id;
  final SheetId sheetId;

  /// Rang de la colonne dans la feuille, à partir de 0.
  final int position;

  /// Nom donné par l'utilisateur ; vide si la colonne n'a pas été renommée.
  final String name;
  final ColumnType type;
  final double width;

  /// Renseigné uniquement pour [ColumnType.reference].
  final ReferenceConfig? reference;

  /// Lettre de la colonne d'après son rang (A, B, …, Z, AA, …).
  String get letter => columnLetter(position);

  /// Libellé affiché : le nom s'il existe, sinon la lettre.
  String get label => name.trim().isEmpty ? letter : name.trim();

  ColumnDef copyWith({
    int? position,
    String? name,
    ColumnType? type,
    double? width,
    ReferenceConfig? reference,
    bool clearReference = false,
  }) => ColumnDef(
    id: id,
    sheetId: sheetId,
    position: position ?? this.position,
    name: name ?? this.name,
    type: type ?? this.type,
    width: width ?? this.width,
    reference: clearReference ? null : (reference ?? this.reference),
  );

  @override
  bool operator ==(Object other) =>
      other is ColumnDef &&
      other.id == id &&
      other.sheetId == sheetId &&
      other.position == position &&
      other.name == name &&
      other.type == type &&
      other.width == width &&
      other.reference == reference;

  @override
  int get hashCode =>
      Object.hash(id, sheetId, position, name, type, width, reference);

  @override
  String toString() => 'ColumnDef($label, $type, #$position)';
}

/// Lettre de colonne façon tableur pour un rang à partir de 0.
String columnLetter(int index) {
  var n = index + 1;
  final buffer = StringBuffer();
  final letters = <int>[];
  while (n > 0) {
    final rem = (n - 1) % 26;
    letters.add(65 + rem);
    n = (n - 1) ~/ 26;
  }
  for (final code in letters.reversed) {
    buffer.writeCharCode(code);
  }
  return buffer.toString();
}
