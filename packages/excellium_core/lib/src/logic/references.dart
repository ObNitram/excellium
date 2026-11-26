import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import 'cell_input.dart';

/// Libellé d'une ligne quand elle est référencée depuis une autre feuille :
/// le contenu de sa première colonne, ou « Ligne N » si elle est vide.
String rowLabel(SheetRow row, List<ColumnDef> columns) {
  final first = columns.isEmpty ? null : columns.first;
  final text = first == null ? '' : plainText(row[first.id]);
  return text.isEmpty ? 'Ligne ${row.position + 1}' : text;
}

/// Texte simple d'une valeur, pour la recherche et les libellés.
String plainText(CellValue? value) => switch (value) {
  null => '',
  ReferenceValue() => '',
  BoolValue(:final value) => value ? 'Vrai' : 'Faux',
  _ => cellInputText(value),
};

/// Lignes de la feuille visée qui correspondent à [query].
///
/// La recherche porte sur [searchColumnIds] ; si la liste est vide ou ne
/// désigne aucune colonne existante, elle porte sur la première colonne. Une
/// ligne sans contenu dans ces colonnes n'est jamais proposée.
List<SheetRow> searchRows(
  List<SheetRow> rows,
  List<ColumnDef> columns, {
  required List<ColumnId> searchColumnIds,
  required String query,
  int limit = 8,
}) {
  final known = {for (final column in columns) column.id};
  var searched = [
    for (final id in searchColumnIds)
      if (known.contains(id)) id,
  ];
  if (searched.isEmpty && columns.isNotEmpty) searched = [columns.first.id];

  final needle = query.trim().toLowerCase();
  final result = <SheetRow>[];
  for (final row in rows) {
    final texts = [for (final id in searched) plainText(row[id])];
    if (texts.every((text) => text.isEmpty)) continue;
    if (needle.isNotEmpty &&
        !texts.any((text) => text.toLowerCase().contains(needle))) {
      continue;
    }
    result.add(row);
    if (result.length >= limit) break;
  }
  return result;
}

/// Ajoute ou retire [rowId] d'une cellule de référence, selon la cardinalité.
CellValue? toggleReference(
  CellValue? current,
  RowId rowId, {
  required Cardinality cardinality,
}) {
  final existing = current is ReferenceValue ? current.rowIds : const <RowId>[];
  if (cardinality == Cardinality.one) {
    return existing.isNotEmpty && existing.first == rowId
        ? null
        : ReferenceValue([rowId]);
  }
  final next = existing.contains(rowId)
      ? [
          for (final id in existing)
            if (id != rowId) id,
        ]
      : [...existing, rowId];
  return next.isEmpty ? null : ReferenceValue(next);
}
