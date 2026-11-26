import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'cell_value.dart';
import 'ids.dart';
import 'style.dart';

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
    this.height,
    Map<ColumnId, CellValue> cells = const {},
    Map<ColumnId, CellStyle> styles = const {},
  }) : cells = Map.unmodifiable(cells),
       styles = Map.unmodifiable(styles);

  static const double defaultHeight = 28;
  static const double minHeight = 20;
  static const double maxHeight = 200;

  final RowId id;
  final SheetId sheetId;

  /// Rang de la ligne dans la feuille, à partir de 0.
  final int position;

  /// Hauteur choisie par l'utilisateur ; `null` pour la hauteur par défaut.
  final double? height;

  /// Valeurs des cellules non vides.
  final Map<ColumnId, CellValue> cells;

  /// Styles propres à certaines cellules, en complément du style de colonne.
  final Map<ColumnId, CellStyle> styles;

  CellValue? operator [](ColumnId columnId) => cells[columnId];

  bool get isEmpty => cells.isEmpty;

  SheetRow copyWith({
    int? position,
    double? height,
    bool clearHeight = false,
    Map<ColumnId, CellValue>? cells,
    Map<ColumnId, CellStyle>? styles,
  }) => SheetRow(
    id: id,
    sheetId: sheetId,
    position: position ?? this.position,
    height: clearHeight ? null : (height ?? this.height),
    cells: cells ?? this.cells,
    styles: styles ?? this.styles,
  );

  /// Copie avec le style d'une cellule modifié ; `null` ou un style vide le
  /// retire.
  SheetRow withStyle(ColumnId columnId, CellStyle? style) {
    final next = Map<ColumnId, CellStyle>.of(styles);
    if (style == null || style.isEmpty) {
      next.remove(columnId);
    } else {
      next[columnId] = style;
    }
    return copyWith(styles: next);
  }

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
      other.height == height &&
      const MapEquality<ColumnId, CellValue>().equals(other.cells, cells) &&
      const MapEquality<ColumnId, CellStyle>().equals(other.styles, styles);

  @override
  int get hashCode => Object.hash(
    id,
    sheetId,
    position,
    height,
    const MapEquality<ColumnId, CellValue>().hash(cells),
    const MapEquality<ColumnId, CellStyle>().hash(styles),
  );

  @override
  String toString() => 'SheetRow(#$position, $cells)';
}
