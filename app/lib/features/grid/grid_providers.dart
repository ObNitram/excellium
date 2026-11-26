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

/// Ce qui est sélectionné dans la feuille : une cellule, une colonne entière
/// ou une case de calcul.
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

/// Une case de calcul sous une colonne, en bas de la grille. [index] est le
/// numéro de la ligne de cases, à partir de 0.
final class CalcCellSelected extends GridSelection {
  const CalcCellSelected(this.index, super.columnId);

  final int index;

  @override
  bool operator ==(Object other) =>
      other is CalcCellSelected &&
      other.index == index &&
      other.columnId == columnId;

  @override
  int get hashCode => Object.hash(CalcCellSelected, index, columnId);
}

/// La case d'une colonne sur une ligne de regroupement. Son contenu vaut
/// pour tous les groupes ; [groupKey] dit sur lequel on a cliqué.
final class GroupCalcSelected extends GridSelection {
  const GroupCalcSelected(super.columnId, this.groupKey);

  final String groupKey;

  @override
  bool operator ==(Object other) =>
      other is GroupCalcSelected &&
      other.columnId == columnId &&
      other.groupKey == groupKey;

  @override
  int get hashCode => Object.hash(GroupCalcSelected, columnId, groupKey);
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

  /// Sélectionne une cellule. Avec [edit], la barre d'édition prend la
  /// saisie : c'est le cas quand on clique sur la cellule dans la grille.
  void select(RowId rowId, ColumnId columnId, {bool edit = false}) {
    state = CellSelected(rowId, columnId);
    if (edit) _requestEdit();
  }

  void selectColumn(ColumnId columnId) => state = ColumnSelected(columnId);

  void selectCalcCell(int index, ColumnId columnId, {bool edit = false}) {
    state = CalcCellSelected(index, columnId);
    if (edit) _requestEdit();
  }

  void selectGroupCalc(
    ColumnId columnId,
    String groupKey, {
    bool edit = false,
  }) {
    state = GroupCalcSelected(columnId, groupKey);
    if (edit) _requestEdit();
  }

  void clear() => state = null;

  void _requestEdit() => ref.read(editRequestProvider.notifier).request();
}

/// Demandes de saisie immédiate : la valeur change à chaque clic sur une
/// case, et la barre d'édition y répond en donnant le focus à son champ.
///
/// C'est un signal à part de la sélection, parce que cliquer une seconde
/// fois sur la case déjà sélectionnée doit aussi rendre la main au champ.
final editRequestProvider = NotifierProvider<EditRequest, int>(EditRequest.new);

class EditRequest extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
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
/// ou la colonne sélectionnée en entier. `null` pour une case de calcul, qui
/// ne se style pas.
final selectedColumnProvider = Provider<ColumnDef?>((ref) {
  final sheet = ref.watch(activeSheetProvider);
  final selection = ref.watch(selectionProvider);
  if (sheet == null ||
      (selection is! CellSelected && selection is! ColumnSelected)) {
    return null;
  }
  return _findColumn(ref, sheet.id, selection!.columnId);
});

/// La colonne de la case de calcul sélectionnée, à jour ; `null` si la
/// sélection n'est pas une case de calcul.
final calcColumnProvider = Provider<ColumnDef?>((ref) {
  final sheet = ref.watch(activeSheetProvider);
  final selection = ref.watch(selectionProvider);
  if (sheet == null ||
      (selection is! CalcCellSelected && selection is! GroupCalcSelected)) {
    return null;
  }
  return _findColumn(ref, sheet.id, selection!.columnId);
});

/// Les calculs d'une feuille : valeurs des colonnes Formule et évaluation des
/// cases de calcul.
final sheetFormulasProvider = Provider.family<SheetFormulas, SheetId>((
  ref,
  sheetId,
) {
  return SheetFormulas(
    engine: ref.watch(formulaEngineProvider),
    columns: ref.watch(columnsProvider(sheetId)).value ?? const [],
    rows: ref.watch(rowsProvider(sheetId)).value ?? const [],
  );
});

/// Volet des cases de calcul, en bas de la grille : sa hauteur et s'il est
/// replié. Réglage d'affichage, gardé le temps de la session.
typedef CalcPaneState = ({double height, bool hidden});

final calcPaneProvider = NotifierProvider<CalcPane, CalcPaneState>(
  CalcPane.new,
);

class CalcPane extends Notifier<CalcPaneState> {
  static const double defaultHeight = 96;
  static const double minHeight = 32;
  static const double maxHeight = 420;

  /// En dessous de cette hauteur, tirer la barre replie le volet.
  static const double collapseBelow = 14;

  @override
  CalcPaneState build() => (height: defaultHeight, hidden: false);

  void setHeight(double height) => state = (
    height: height.clamp(minHeight, maxHeight).toDouble(),
    hidden: false,
  );

  void toggle() => state = (height: state.height, hidden: !state.hidden);

  void hide() => state = (height: state.height, hidden: true);

  void reset() => state = (height: defaultHeight, hidden: false);
}

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
