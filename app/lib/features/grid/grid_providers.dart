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

/// Coordonnées d'une cellule, par identifiants stables.
typedef CellRef = ({RowId rowId, ColumnId columnId});

/// La cellule sélectionnée dans la feuille affichée.
final selectionProvider = NotifierProvider<Selection, CellRef?>(Selection.new);

class Selection extends Notifier<CellRef?> {
  @override
  CellRef? build() {
    // Changer d'onglet annule la sélection.
    ref.watch(activeSheetProvider.select((sheet) => sheet?.id));
    return null;
  }

  void select(RowId rowId, ColumnId columnId) =>
      state = (rowId: rowId, columnId: columnId);

  void clear() => state = null;
}

/// La cellule sélectionnée avec sa ligne et sa colonne à jour.
typedef SelectedCell = ({SheetRow row, ColumnDef column});

final selectedCellProvider = Provider<SelectedCell?>((ref) {
  final sheet = ref.watch(activeSheetProvider);
  final selection = ref.watch(selectionProvider);
  if (sheet == null || selection == null) return null;
  final columns = ref.watch(columnsProvider(sheet.id)).value ?? const [];
  final rows = ref.watch(rowsProvider(sheet.id)).value ?? const [];
  ColumnDef? column;
  for (final candidate in columns) {
    if (candidate.id == selection.columnId) column = candidate;
  }
  SheetRow? row;
  for (final candidate in rows) {
    if (candidate.id == selection.rowId) row = candidate;
  }
  if (column == null || row == null) return null;
  return (row: row, column: column);
});
