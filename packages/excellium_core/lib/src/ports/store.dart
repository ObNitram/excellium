import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import '../model/sheet.dart';
import '../model/style.dart';
import '../model/view.dart';

/// Interfaces de stockage (« ports »).
///
/// Le cœur métier et l'application ne connaissent que ces interfaces. Chaque
/// moteur de stockage (SQLite via Drift aujourd'hui, un serveur demain) en
/// fournit une implémentation, vérifiée par la suite de tests de contrat du
/// paquet `excellium_store_contract`.
///
/// Les flux `watch…` émettent l'état courant dès l'abonnement, puis à chaque
/// modification.

/// Les feuilles du classeur, triées par rang.
abstract interface class SheetRepository {
  Stream<List<Sheet>> watchSheets();

  Future<List<Sheet>> getSheets();

  /// Crée une feuille en dernière position.
  Future<Sheet> createSheet({required String name});

  Future<void> renameSheet(SheetId id, String name);

  /// Réordonne les feuilles ; [orderedIds] doit contenir tous les identifiants.
  Future<void> reorderSheets(List<SheetId> orderedIds);

  /// Supprime la feuille avec ses colonnes, ses lignes et ses cellules.
  Future<void> deleteSheet(SheetId id);
}

/// Les colonnes d'une feuille, triées par rang.
abstract interface class ColumnRepository {
  Stream<List<ColumnDef>> watchColumns(SheetId sheetId);

  Future<List<ColumnDef>> getColumns(SheetId sheetId);

  /// Ajoute une colonne en dernière position.
  Future<ColumnDef> addColumn(
    SheetId sheetId, {
    String name = '',
    ColumnType type = ColumnType.text,
  });

  /// Enregistre le nom, le type, la largeur, le style, les catégories et les
  /// paramètres de [column]. Le rang se change avec [reorderColumns].
  Future<void> updateColumn(ColumnDef column);

  /// Réordonne les colonnes ; [orderedIds] doit contenir tous les identifiants
  /// de la feuille.
  Future<void> reorderColumns(SheetId sheetId, List<ColumnId> orderedIds);

  /// Supprime la colonne et les cellules qu'elle contient.
  Future<void> deleteColumn(ColumnId id);
}

/// Les lignes d'une feuille et leurs cellules, triées par rang.
abstract interface class RowRepository {
  Stream<List<SheetRow>> watchRows(SheetId sheetId);

  Future<List<SheetRow>> getRows(SheetId sheetId);

  /// Ajoute une ligne vide en dernière position.
  Future<SheetRow> addRow(SheetId sheetId);

  /// Écrit une cellule ; `null` la vide.
  Future<void> setCell(RowId rowId, ColumnId columnId, CellValue? value);

  /// Écrit le style propre à une cellule ; `null` ou un style vide le retire.
  Future<void> setCellStyle(RowId rowId, ColumnId columnId, CellStyle? style);

  /// Règle la hauteur d'une ligne ; `null` rétablit la hauteur par défaut.
  Future<void> setRowHeight(RowId rowId, double? height);

  /// Supprime la ligne et ses cellules.
  Future<void> deleteRow(RowId id);
}

/// Les vues enregistrées d'une feuille, triées par rang.
abstract interface class ViewRepository {
  Stream<List<SavedView>> watchViews(SheetId sheetId);

  Future<List<SavedView>> getViews(SheetId sheetId);

  /// Enregistre une nouvelle vue en dernière position.
  Future<SavedView> createView(
    SheetId sheetId, {
    required String name,
    required ViewSpec spec,
  });

  /// Enregistre le nom et le contenu de [view]. Le rang ne change pas.
  Future<void> updateView(SavedView view);

  Future<void> deleteView(ViewId id);
}

/// Copie de tout le contenu d'un classeur, prise par [ExcelliumStore.snapshot]
/// pour pouvoir annuler une modification.
///
/// Son contenu est propre à chaque moteur de stockage : seul celui qui l'a
/// prise sait la restaurer.
abstract interface class WorkbookSnapshot {}

/// Point d'entrée d'un moteur de stockage.
abstract interface class ExcelliumStore {
  SheetRepository get sheets;

  ColumnRepository get columns;

  RowRepository get rows;

  ViewRepository get views;

  /// Exécute [action] de façon atomique : tout est enregistré, ou rien.
  Future<T> transaction<T>(Future<T> Function() action);

  /// Copie tout le classeur : feuilles, colonnes, lignes, cellules, styles
  /// et vues enregistrées.
  Future<WorkbookSnapshot> snapshot();

  /// Remet le classeur exactement dans l'état de [snapshot], identifiants
  /// compris, et prévient les flux ouverts. [snapshot] doit venir de ce même
  /// stockage.
  Future<void> restore(WorkbookSnapshot snapshot);

  Future<void> close();
}
