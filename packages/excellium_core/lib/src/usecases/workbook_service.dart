import '../logic/categories.dart';
import '../logic/cell_input.dart';
import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import '../model/sheet.dart';
import '../model/style.dart';
import '../model/view.dart';
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

  /// Règle la hauteur d'une ligne, bornée ; `null` rétablit la hauteur par
  /// défaut.
  Future<void> resizeRow(SheetRow row, double? height) =>
      _store.rows.setRowHeight(
        row.id,
        height?.clamp(SheetRow.minHeight, SheetRow.maxHeight).toDouble(),
      );

  /// Applique [patch] au style de toute la colonne.
  ///
  /// Les cellules qui avaient un réglage individuel pour ces propriétés le
  /// perdent : c'est le réglage de la colonne qui s'applique partout.
  Future<void> styleColumn(ColumnDef column, CellStyle patch) {
    return _store.transaction(() async {
      await _store.columns.updateColumn(
        column.copyWith(style: column.style.merge(patch)),
      );
      final rows = await _store.rows.getRows(column.sheetId);
      for (final row in rows) {
        final own = row.styles[column.id];
        if (own == null) continue;
        final cleaned = own.without(patch);
        if (cleaned != own) {
          await _store.rows.setCellStyle(row.id, column.id, cleaned);
        }
      }
    });
  }

  /// Applique [patch] au style d'une seule cellule.
  Future<void> styleCell(SheetRow row, ColumnDef column, CellStyle patch) =>
      _store.rows.setCellStyle(
        row.id,
        column.id,
        (row.styles[column.id] ?? CellStyle.none).merge(patch),
      );

  /// Choisit ou retire une catégorie dans une cellule, et l'ajoute aux
  /// catégories définies de la colonne si elle est nouvelle.
  Future<void> toggleCellCategory(
    SheetRow row,
    ColumnDef column,
    String category,
  ) {
    final name = category.trim();
    if (name.isEmpty) return Future.value();
    return _store.transaction(() async {
      if (!column.options.contains(name)) {
        await _store.columns.updateColumn(
          column.copyWith(options: [...column.options, name]),
        );
      }
      await _store.rows.setCell(
        row.id,
        column.id,
        toggleCategory(
          row[column.id],
          name,
          multiple: column.type == ColumnType.multiCategory,
        ),
      );
    });
  }

  /// Fixe l'ordre des catégories d'une colonne (l'ordre des étapes d'un
  /// kanban). Les catégories seulement présentes dans les cellules sont
  /// enregistrées au passage.
  Future<void> reorderCategories(ColumnDef column, List<String> ordered) =>
      _store.columns.updateColumn(column.copyWith(options: ordered));

  /// Règle la feuille visée, la cardinalité et les colonnes de recherche d'une
  /// colonne Référence.
  Future<void> configureReference(ColumnDef column, ReferenceConfig config) =>
      _store.columns.updateColumn(column.copyWith(reference: config));

  /// Enregistre une vue. Sans [name], elle s'appelle « Vue N ».
  Future<SavedView> saveView(SheetId sheetId, ViewSpec spec, {String? name}) {
    return _store.transaction(() async {
      final existing = await _store.views.getViews(sheetId);
      final names = {for (final view in existing) view.name};
      var label = name?.trim() ?? '';
      if (label.isEmpty) {
        var n = existing.length + 1;
        while (names.contains('Vue $n')) {
          n++;
        }
        label = 'Vue $n';
      }
      return _store.views.createView(
        sheetId,
        name: label,
        spec: spec.normalized,
      );
    });
  }

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
