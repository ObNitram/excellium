import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'ids.dart';
import 'style.dart';

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

  /// Colonne calculée : sa valeur vient d'une formule, pas d'une saisie.
  formula,
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
    this.style = CellStyle.none,
    this.options = const [],
    this.formula = '',
    this.groupCalc = '',
    this.calcCells = const {},
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

  /// Style appliqué à toutes les cellules de la colonne.
  final CellStyle style;

  /// Catégories définies pour une colonne Catégorie, dans l'ordre choisi par
  /// l'utilisateur. C'est aussi l'ordre des étapes d'un kanban.
  final List<String> options;

  /// Formule d'une colonne [ColumnType.formula], par exemple
  /// `Quantité × Prix`. Vide pour les autres types.
  final String formula;

  /// Contenu de la case de cette colonne sur les lignes de regroupement : un
  /// texte, ou un calcul qui commence par `=` et que chaque groupe évalue sur
  /// ses propres lignes.
  final String groupCalc;

  /// Cases de calcul sous la colonne, en bas de la grille : contenu par
  /// numéro de ligne (à partir de 0). Même convention que [groupCalc], sur
  /// toute la table.
  final Map<int, String> calcCells;

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
    CellStyle? style,
    List<String>? options,
    String? formula,
    String? groupCalc,
    Map<int, String>? calcCells,
  }) => ColumnDef(
    id: id,
    sheetId: sheetId,
    position: position ?? this.position,
    name: name ?? this.name,
    type: type ?? this.type,
    width: width ?? this.width,
    reference: clearReference ? null : (reference ?? this.reference),
    style: style ?? this.style,
    options: options ?? this.options,
    formula: formula ?? this.formula,
    groupCalc: groupCalc ?? this.groupCalc,
    calcCells: calcCells ?? this.calcCells,
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
      other.reference == reference &&
      other.style == style &&
      other.formula == formula &&
      other.groupCalc == groupCalc &&
      const MapEquality<int, String>().equals(other.calcCells, calcCells) &&
      const ListEquality<String>().equals(other.options, options);

  @override
  int get hashCode => Object.hash(
    id,
    sheetId,
    position,
    name,
    type,
    width,
    reference,
    style,
    formula,
    groupCalc,
    const MapEquality<int, String>().hash(calcCells),
    const ListEquality<String>().hash(options),
  );

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
