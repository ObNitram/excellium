import 'package:drift/drift.dart';

part 'database.g.dart';

/// Schéma SQLite. Rien de ce fichier n'est exporté du paquet : le reste de
/// l'application ne voit que les interfaces d'`excellium_core`.

@DataClassName('SheetRecord')
class SheetRecords extends Table {
  @override
  String get tableName => 'sheets';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ColumnRecord')
class ColumnRecords extends Table {
  @override
  String get tableName => 'columns';

  TextColumn get id => text()();
  TextColumn get sheetId =>
      text().references(SheetRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get position => integer()();
  RealColumn get width => real()();

  /// Paramètres d'une colonne Référence, en JSON ; `null` pour les autres.
  TextColumn get reference => text().nullable()();

  /// Style de la colonne, en JSON ; `null` s'il n'y en a pas.
  TextColumn get style => text().nullable()();

  /// Catégories définies, en JSON ; `null` s'il n'y en a pas.
  TextColumn get options => text().nullable()();

  /// Formule d'une colonne Formule ; `null` s'il n'y en a pas.
  TextColumn get formula => text().nullable()();

  /// Contenu de la case de la colonne sur les lignes de regroupement.
  TextColumn get groupCalc => text().nullable()();

  /// Cases de calcul sous la colonne, en JSON (numéro de ligne → contenu).
  TextColumn get calcCells => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RowRecord')
class RowRecords extends Table {
  @override
  String get tableName => 'rows';

  TextColumn get id => text()();
  TextColumn get sheetId =>
      text().references(SheetRecords, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  /// Hauteur choisie ; `null` pour la hauteur par défaut.
  RealColumn get height => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CellRecord')
class CellRecords extends Table {
  @override
  String get tableName => 'cells';

  TextColumn get rowId =>
      text().references(RowRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get columnId =>
      text().references(ColumnRecords, #id, onDelete: KeyAction.cascade)();

  /// Valeur typée, en JSON (voir `cell_codec.dart`).
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {rowId, columnId};
}

/// Style propre à une cellule. Table séparée des valeurs : une cellule vide
/// peut avoir un style.
@DataClassName('CellStyleRecord')
class CellStyleRecords extends Table {
  @override
  String get tableName => 'cell_styles';

  TextColumn get rowId =>
      text().references(RowRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get columnId =>
      text().references(ColumnRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get style => text()();

  @override
  Set<Column<Object>> get primaryKey => {rowId, columnId};
}

@DataClassName('ViewRecord')
class ViewRecords extends Table {
  @override
  String get tableName => 'views';

  TextColumn get id => text()();
  TextColumn get sheetId =>
      text().references(SheetRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get position => integer()();

  /// Affichage, tri, filtres et colonnes masquées, en JSON.
  TextColumn get spec => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SheetRecords,
    ColumnRecords,
    RowRecords,
    CellRecords,
    CellStyleRecords,
    ViewRecords,
  ],
)
class ExcelliumDatabase extends _$ExcelliumDatabase {
  ExcelliumDatabase(super.executor);

  /// Version 2 : styles de colonne et de cellule, catégories définies,
  /// hauteur de ligne, vues enregistrées.
  ///
  /// Version 3 : formule de colonne, case de regroupement, cases de calcul.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(columnRecords, columnRecords.style);
        await m.addColumn(columnRecords, columnRecords.options);
        await m.addColumn(rowRecords, rowRecords.height);
        await m.createTable(cellStyleRecords);
        await m.createTable(viewRecords);
      }
      if (from < 3) {
        await m.addColumn(columnRecords, columnRecords.formula);
        await m.addColumn(columnRecords, columnRecords.groupCalc);
        await m.addColumn(columnRecords, columnRecords.calcCells);
      }
    },
    beforeOpen: (details) async {
      // Sans cette ligne SQLite ignore les suppressions en cascade.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
