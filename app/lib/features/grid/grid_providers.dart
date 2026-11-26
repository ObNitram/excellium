import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';
import '../workbook/workbook_providers.dart';

/// Les colonnes d'une feuille, dans l'ordre d'affichage.
final columnsProvider = StreamProvider.family<List<ColumnDef>, SheetId>(
  (ref, sheetId) => ref.watch(storeProvider).columns.watchColumns(sheetId),
);

/// Les lignes d'une feuille avec leurs cellules.
final rowsProvider = StreamProvider.family<List<SheetRow>, SheetId>(
  (ref, sheetId) => ref.watch(storeProvider).rows.watchRows(sheetId),
);

/// Libellé de chaque ligne d'une feuille, pour l'afficher là où elle est
/// référencée.
final rowLabelsProvider = Provider.family<Map<RowId, String>, SheetId>((
  ref,
  sheetId,
) {
  final columns = ref.watch(columnsProvider(sheetId)).value ?? const [];
  final rows = ref.watch(rowsProvider(sheetId)).value ?? const [];
  return {for (final row in rows) row.id: rowLabel(row, columns)};
});

/// Ce qui est sélectionné dans la feuille : une cellule ou une colonne
/// entière.
sealed class GridSelection {
  const GridSelection(this.columnId);

  final ColumnId columnId;
}

final class CellSelected extends GridSelection {
  const CellSelected(this.rowId, super.columnId);

  final RowId rowId;

  @override
  bool operator ==(Object other) =>
      other is CellSelected &&
      other.rowId == rowId &&
      other.columnId == columnId;

  @override
  int get hashCode => Object.hash(rowId, columnId);
}

final class ColumnSelected extends GridSelection {
  const ColumnSelected(super.columnId);

  @override
  bool operator ==(Object other) =>
      other is ColumnSelected && other.columnId == columnId;

  @override
  int get hashCode => Object.hash(ColumnSelected, columnId);
}

final selectionProvider = NotifierProvider<Selection, GridSelection?>(
  Selection.new,
);

class Selection extends Notifier<GridSelection?> {
  @override
  GridSelection? build() {
    // Changer d'onglet annule la sélection.
    ref.watch(activeSheetProvider.select((sheet) => sheet?.id));
    return null;
  }

  void select(RowId rowId, ColumnId columnId) =>
      state = CellSelected(rowId, columnId);

  void selectColumn(ColumnId columnId) => state = ColumnSelected(columnId);

  void clear() => state = null;
}

/// La cellule sélectionnée avec sa ligne et sa colonne à jour ; `null` si
/// rien n'est sélectionné ou si c'est une colonne entière.
typedef SelectedCell = ({SheetRow row, ColumnDef column});

final selectedCellProvider = Provider<SelectedCell?>((ref) {
  final sheet = ref.watch(activeSheetProvider);
  final selection = ref.watch(selectionProvider);
  if (sheet == null || selection is! CellSelected) return null;
  final column = _findColumn(ref, sheet.id, selection.columnId);
  final rows = ref.watch(rowsProvider(sheet.id)).value ?? const [];
  SheetRow? row;
  for (final candidate in rows) {
    if (candidate.id == selection.rowId) row = candidate;
  }
  if (column == null || row == null) return null;
  return (row: row, column: column);
});

/// La colonne concernée par la sélection : celle de la cellule sélectionnée,
/// ou la colonne sélectionnée en entier.
final selectedColumnProvider = Provider<ColumnDef?>((ref) {
  final sheet = ref.watch(activeSheetProvider);
  final selection = ref.watch(selectionProvider);
  if (sheet == null || selection == null) return null;
  return _findColumn(ref, sheet.id, selection.columnId);
});

ColumnDef? _findColumn(Ref ref, SheetId sheetId, ColumnId columnId) {
  final columns = ref.watch(columnsProvider(sheetId)).value ?? const [];
  for (final column in columns) {
    if (column.id == columnId) return column;
  }
  return null;
}

/// Taille en cours de réglage à la souris, avant d'être enregistrée : la
/// grille suit le geste sans écrire dans le stockage à chaque pixel.
typedef ResizePreview = ({String id, double size});

final columnResizeProvider = NotifierProvider<ResizeState, ResizePreview?>(
  ResizeState.new,
);

final rowResizeProvider = NotifierProvider<ResizeState, ResizePreview?>(
  ResizeState.new,
);

class ResizeState extends Notifier<ResizePreview?> {
  @override
  ResizePreview? build() => null;

  void update(String id, double size) => state = (id: id, size: size);

  void end() => state = null;
}
