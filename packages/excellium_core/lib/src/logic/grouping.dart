import 'package:meta/meta.dart';

import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import 'categories.dart';

/// Vrai si on peut regrouper les lignes selon une colonne de ce type.
bool canGroupBy(ColumnType type) =>
    type == ColumnType.singleCategory ||
    type == ColumnType.multiCategory ||
    type == ColumnType.reference;

/// Un groupe de lignes qui partagent une valeur de la colonne de regroupement.
@immutable
final class RowGroup {
  const RowGroup({this.category, this.reference, required this.rows});

  /// La catégorie commune, pour une colonne Catégorie.
  final String? category;

  /// La ligne référencée commune, pour une colonne Référence.
  final RowId? reference;

  /// Les lignes du groupe, dans l'ordre de la vue.
  final List<SheetRow> rows;

  /// Le groupe des lignes sans valeur dans la colonne.
  bool get isNone => category == null && reference == null;

  /// Identifiant stable du groupe dans sa colonne.
  String get key => category != null
      ? 'c:$category'
      : reference != null
      ? 'r:${reference!.value}'
      : '';

  /// La valeur à donner à une ligne pour qu'elle entre dans ce groupe.
  CellValue? valueFor(ColumnDef column) {
    if (category case final name?) {
      return column.type == ColumnType.multiCategory
          ? CategoryValue([name])
          : CategoryValue.single(name);
    }
    if (reference case final id?) return ReferenceValue([id]);
    return null;
  }
}

/// Répartit [shown] en groupes selon les valeurs de [column].
///
/// - [shown] : les lignes de la vue, déjà filtrées et triées ; les lignes
///   entièrement vides sont ignorées.
/// - [all] : toutes les lignes de la feuille, pour connaître les valeurs
///   existantes.
/// - [referenceOrder] : l'ordre des lignes de la feuille liée, qui fixe
///   l'ordre des groupes d'une colonne Référence.
/// - [hideEmpty] : masque les groupes sans ligne (quand un filtre est actif).
///
/// Une ligne qui a plusieurs valeurs (catégories multiples, relation n – n)
/// apparaît dans chacun de ses groupes. Les lignes sans valeur forment un
/// dernier groupe. L'ordre des groupes est celui des catégories de la
/// colonne, ou celui de la feuille liée.
List<RowGroup> groupRows({
  required ColumnDef column,
  required List<SheetRow> shown,
  required List<SheetRow> all,
  List<RowId> referenceOrder = const [],
  bool hideEmpty = false,
}) {
  if (!canGroupBy(column.type)) return const [];
  final rows = [
    for (final row in shown)
      if (!row.isEmpty) row,
  ];
  final groups = <RowGroup>[];

  if (column.type == ColumnType.reference) {
    final found = <RowId>[];
    for (final row in all) {
      if (row[column.id] case ReferenceValue(:final rowIds)) {
        for (final id in rowIds) {
          if (!found.contains(id)) found.add(id);
        }
      }
    }
    final rank = {for (final (index, id) in referenceOrder.indexed) id: index};
    // Les références vers des lignes disparues restent à la fin, dans leur
    // ordre d'apparition.
    final ordered = [
      ...found.where(rank.containsKey).toList()
        ..sort((a, b) => rank[a]!.compareTo(rank[b]!)),
      ...found.where((id) => !rank.containsKey(id)),
    ];
    for (final id in ordered) {
      final members = [
        for (final row in rows)
          if (row[column.id] case ReferenceValue(:final rowIds)
              when rowIds.contains(id))
            row,
      ];
      if (members.isEmpty && hideEmpty) continue;
      groups.add(RowGroup(reference: id, rows: members));
    }
  } else {
    for (final category in categoriesOf(column, all)) {
      final members = [
        for (final row in rows)
          if (row[column.id] case CategoryValue(:final categories)
              when categories.contains(category))
            row,
      ];
      if (members.isEmpty && hideEmpty) continue;
      groups.add(RowGroup(category: category, rows: members));
    }
  }

  final none = [
    for (final row in rows)
      if (row[column.id] == null) row,
  ];
  if (none.isNotEmpty) groups.add(RowGroup(rows: none));
  return groups;
}
