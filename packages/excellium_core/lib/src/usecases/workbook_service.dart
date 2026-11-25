import '../logic/cell_input.dart';
import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import '../model/sheet.dart';
import '../ports/store.dart';

/// Cas d'usage du classeur : les règles qui enchaînent plusieurs opérations
/// de stockage. L'interface n'appelle jamais les dépôts pour ces actions.
final class WorkbookService {
  const WorkbookService(this._store);

  final ExcelliumStore _store;

  static const int defaultColumnCount = 6;
  static const int defaultRowCount = 20;

  /// Crée une première feuille si le classeur est vide.
  Future<void> ensureDefaultSheet() async {
    final sheets = await _store.sheets.getSheets();
    if (sheets.isEmpty) await createSheet();
  }

  /// Crée une feuille avec des colonnes Texte et des lignes vides.
  ///
  /// Sans [name], la feuille s'appelle « Feuille N », N étant le premier
  /// numéro libre.
  Future<Sheet> createSheet({
    String? name,
    int columnCount = defaultColumnCount,
    int rowCount = defaultRowCount,
  }) {
    return _store.transaction(() async {
      final existing = await _store.sheets.getSheets();
      final sheet = await _store.sheets.createSheet(
        name: name?.trim().isNotEmpty == true
            ? name!.trim()
            : _nextSheetName(existing),
      );
      for (var i = 0; i < columnCount; i++) {
        await _store.columns.addColumn(sheet.id);
      }
      for (var i = 0; i < rowCount; i++) {
        await _store.rows.addRow(sheet.id);
      }
      return sheet;
    });
  }

  /// Déplace une feuille du rang [from] au rang [to].
  Future<void> moveSheet(int from, int to) async {
    final sheets = await _store.sheets.getSheets();
    final ids = _moved([for (final sheet in sheets) sheet.id], from, to);
    if (ids != null) await _store.sheets.reorderSheets(ids);
  }

  /// Déplace une colonne du rang [from] au rang [to].
  Future<void> moveColumn(SheetId sheetId, int from, int to) async {
    final columns = await _store.columns.getColumns(sheetId);
    final ids = _moved([for (final column in columns) column.id], from, to);
    if (ids != null) await _store.columns.reorderColumns(sheetId, ids);
  }

  /// Renomme une colonne ; un nom vide rétablit la lettre.
  Future<void> renameColumn(ColumnDef column, String name) =>
      _store.columns.updateColumn(column.copyWith(name: name.trim()));

  /// Règle la largeur d'une colonne, bornée aux limites autorisées.
  Future<void> resizeColumn(ColumnDef column, double width) =>
      _store.columns.updateColumn(
        column.copyWith(
          width: width.clamp(ColumnDef.minWidth, ColumnDef.maxWidth).toDouble(),
        ),
      );

  /// Change le type d'une colonne et convertit les valeurs existantes.
  ///
  /// Une valeur qui n'a pas de sens dans le nouveau type est effacée. Le tout
  /// est atomique : la colonne n'est jamais dans un type avec des valeurs d'un
  /// autre.
  Future<void> changeColumnType(ColumnDef column, ColumnType type) {
    if (column.type == type) return Future.value();
    return _store.transaction(() async {
      await _store.columns.updateColumn(
        column.copyWith(
          type: type,
          reference: type == ColumnType.reference
              ? (column.reference ?? const ReferenceConfig())
              : null,
          clearReference: type != ColumnType.reference,
        ),
      );
      final rows = await _store.rows.getRows(column.sheetId);
      for (final row in rows) {
        final before = row[column.id];
        if (before == null) continue;
        final after = convertCellValue(before, type);
        if (after != before) {
          await _store.rows.setCell(row.id, column.id, after);
        }
      }
    });
  }

  /// Enregistre un texte saisi dans une cellule, selon le type de la colonne.
  ///
  /// Renvoie l'erreur si la saisie est refusée ; la cellule est alors
  /// inchangée.
  Future<CellInputError?> enterText(
    SheetRow row,
    ColumnDef column,
    String input,
  ) async {
    final result = parseCellInput(column.type, input);
    switch (result) {
      case CellInputRejected(:final error):
        return error;
      case CellInputOk(:final value):
        if (value != row[column.id]) {
          await _store.rows.setCell(row.id, column.id, value);
        }
        return null;
    }
  }

  /// Écrit directement une valeur typée (case à cocher, sélecteur de date…).
  Future<void> setValue(SheetRow row, ColumnDef column, CellValue? value) {
    if (value != null && !value.fits(column.type)) {
      throw ArgumentError.value(
        value,
        'value',
        'incompatible avec une colonne ${column.type.name}',
      );
    }
    return _store.rows.setCell(row.id, column.id, value);
  }

  static String _nextSheetName(List<Sheet> existing) {
    final names = {for (final sheet in existing) sheet.name};
    var n = existing.length + 1;
    while (names.contains('Feuille $n')) {
      n++;
    }
    return 'Feuille $n';
  }

  /// Liste réordonnée, ou `null` si le déplacement ne change rien.
  static List<T>? _moved<T>(List<T> items, int from, int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= items.length ||
        to >= items.length) {
      return null;
    }
    final result = List<T>.of(items);
    result.insert(to, result.removeAt(from));
    return result;
  }
}
