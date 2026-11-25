import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'cell_value.dart';
import 'ids.dart';

/// Une ligne d'une feuille.
///
/// Nommée `SheetRow` pour ne pas entrer en conflit avec le widget `Row` de
/// Flutter. Les cellules sont indexées par identifiant de colonne : déplacer
/// ou renommer une colonne ne touche donc pas aux lignes.
@immutable
final class SheetRow {
  SheetRow({
    required this.id,
    required this.sheetId,
    required this.position,
    Map<ColumnId, CellValue> cells = const {},
  }) : cells = Map.unmodifiable(cells);

  final RowId id;
  final SheetId sheetId;

  /// Rang de la ligne dans la feuille, à partir de 0.
  final int position;

  /// Valeurs des cellules non vides.
  final Map<ColumnId, CellValue> cells;

  CellValue? operator [](ColumnId columnId) => cells[columnId];

  bool get isEmpty => cells.isEmpty;

  SheetRow copyWith({int? position, Map<ColumnId, CellValue>? cells}) =>
      SheetRow(
        id: id,
        sheetId: sheetId,
        position: position ?? this.position,
        cells: cells ?? this.cells,
      );

  /// Copie avec une cellule modifiée ; `null` vide la cellule.
  SheetRow withCell(ColumnId columnId, CellValue? value) {
    final next = Map<ColumnId, CellValue>.of(cells);
    if (value == null) {
      next.remove(columnId);
    } else {
      next[columnId] = value;
    }
    return copyWith(cells: next);
  }

  @override
  bool operator ==(Object other) =>
      other is SheetRow &&
      other.id == id &&
      other.sheetId == sheetId &&
      other.position == position &&
      const MapEquality<ColumnId, CellValue>().equals(other.cells, cells);

  @override
  int get hashCode => Object.hash(
    id,
    sheetId,
    position,
    const MapEquality<ColumnId, CellValue>().hash(cells),
  );

  @override
  String toString() => 'SheetRow(#$position, $cells)';
}
