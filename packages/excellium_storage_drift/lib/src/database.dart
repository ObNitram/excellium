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

@DriftDatabase(tables: [SheetRecords, ColumnRecords, RowRecords, CellRecords])
class ExcelliumDatabase extends _$ExcelliumDatabase {
  ExcelliumDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Sans cette ligne SQLite ignore les suppressions en cascade.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
