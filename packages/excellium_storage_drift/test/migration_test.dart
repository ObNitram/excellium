import 'package:drift/native.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_storage_drift/excellium_storage_drift.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// Schéma de la version 1, tel qu'il a été créé chez les premiers
/// utilisateurs.
const _schemaV1 = '''
CREATE TABLE sheets (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, position INTEGER NOT NULL);
CREATE TABLE columns (id TEXT NOT NULL PRIMARY KEY, sheet_id TEXT NOT NULL REFERENCES sheets (id) ON DELETE CASCADE, name TEXT NOT NULL, type TEXT NOT NULL, position INTEGER NOT NULL, width REAL NOT NULL, reference TEXT NULL);
CREATE TABLE rows (id TEXT NOT NULL PRIMARY KEY, sheet_id TEXT NOT NULL REFERENCES sheets (id) ON DELETE CASCADE, position INTEGER NOT NULL);
CREATE TABLE cells (row_id TEXT NOT NULL REFERENCES rows (id) ON DELETE CASCADE, column_id TEXT NOT NULL REFERENCES columns (id) ON DELETE CASCADE, value TEXT NOT NULL, PRIMARY KEY (row_id, column_id));
INSERT INTO sheets VALUES ('s1', 'Tâches', 0);
INSERT INTO columns VALUES ('c1', 's1', 'Budget', 'number', 0, 150.0, NULL);
INSERT INTO rows VALUES ('r1', 's1', 0);
INSERT INTO cells VALUES ('r1', 'c1', '{"t":"number","v":1234.5}');
PRAGMA user_version = 1;
''';

/// Schéma de la version 2 : avant les formules et les cases de calcul.
const _schemaV2 = '''
CREATE TABLE sheets (id TEXT NOT NULL, name TEXT NOT NULL, position INTEGER NOT NULL, PRIMARY KEY (id));
CREATE TABLE columns (id TEXT NOT NULL, sheet_id TEXT NOT NULL REFERENCES sheets (id) ON DELETE CASCADE, name TEXT NOT NULL, type TEXT NOT NULL, position INTEGER NOT NULL, width REAL NOT NULL, reference TEXT NULL, style TEXT NULL, options TEXT NULL, PRIMARY KEY (id));
CREATE TABLE rows (id TEXT NOT NULL, sheet_id TEXT NOT NULL REFERENCES sheets (id) ON DELETE CASCADE, position INTEGER NOT NULL, height REAL NULL, PRIMARY KEY (id));
CREATE TABLE cells (row_id TEXT NOT NULL REFERENCES rows (id) ON DELETE CASCADE, column_id TEXT NOT NULL REFERENCES columns (id) ON DELETE CASCADE, value TEXT NOT NULL, PRIMARY KEY (row_id, column_id));
CREATE TABLE cell_styles (row_id TEXT NOT NULL REFERENCES rows (id) ON DELETE CASCADE, column_id TEXT NOT NULL REFERENCES columns (id) ON DELETE CASCADE, style TEXT NOT NULL, PRIMARY KEY (row_id, column_id));
CREATE TABLE views (id TEXT NOT NULL, sheet_id TEXT NOT NULL REFERENCES sheets (id) ON DELETE CASCADE, name TEXT NOT NULL, position INTEGER NOT NULL, spec TEXT NOT NULL, PRIMARY KEY (id));
INSERT INTO sheets VALUES ('s1', 'Tâches', 0);
INSERT INTO columns VALUES ('c1', 's1', 'Statut', 'singleCategory', 0, 150.0, NULL, '{"bold":true}', '["À faire","Terminé"]');
INSERT INTO rows VALUES ('r1', 's1', 0, 44.0);
INSERT INTO cells VALUES ('r1', 'c1', '{"t":"category","v":["Terminé"]}');
INSERT INTO views VALUES ('v1', 's1', 'Terminées', 0, '{"layout":"kanban","key":"c1","sort":null,"filters":{},"hidden":[]}');
PRAGMA user_version = 2;
''';

void main() {
  test(
    'une base en version 2 est mise à niveau sans perdre de données',
    () async {
      final raw = sqlite3.openInMemory()..execute(_schemaV2);
      final store = DriftStore(NativeDatabase.opened(raw));
      addTearDown(store.close);

      final sheet = (await store.sheets.getSheets()).single;
      final column = (await store.columns.getColumns(sheet.id)).single;
      final row = (await store.rows.getRows(sheet.id)).single;
      final view = (await store.views.getViews(sheet.id)).single;

      // Les données d'origine sont intactes.
      expect(column.name, 'Statut');
      expect(column.style, const CellStyle(bold: true));
      expect(column.options, ['À faire', 'Terminé']);
      expect(row.height, 44);
      expect(row[column.id], CategoryValue.single('Terminé'));
      expect(view.spec.layout, ViewLayout.kanban(column.id));

      // Les nouveautés ont leurs valeurs par défaut…
      expect(column.formula, isEmpty);
      expect(column.groupCalc, isEmpty);
      expect(column.calcCells, isEmpty);
      expect(view.spec.groupBy, isNull);

      // …et sont utilisables.
      await store.columns.updateColumn(
        column.copyWith(
          groupCalc: '=Nombre(Statut)',
          calcCells: const {1: 'x'},
        ),
      );
      final formula = await store.columns.addColumn(
        sheet.id,
        type: ColumnType.formula,
      );
      await store.columns.updateColumn(formula.copyWith(formula: 'A + 1'));
      await store.views.createView(
        sheet.id,
        name: 'Groupée',
        spec: ViewSpec(groupBy: column.id),
      );

      final columns = await store.columns.getColumns(sheet.id);
      expect(columns.first.groupCalc, '=Nombre(Statut)');
      expect(columns.first.calcCells, {1: 'x'});
      expect(columns.last.formula, 'A + 1');
      expect(
        (await store.views.getViews(sheet.id)).last.spec.groupBy,
        column.id,
      );
    },
  );

  test(
    'une base en version 1 est mise à niveau sans perdre de données',
    () async {
      final raw = sqlite3.openInMemory()..execute(_schemaV1);
      final store = DriftStore(NativeDatabase.opened(raw));
      addTearDown(store.close);

      final sheet = (await store.sheets.getSheets()).single;
      final column = (await store.columns.getColumns(sheet.id)).single;
      final row = (await store.rows.getRows(sheet.id)).single;

      // Les données d'origine sont intactes.
      expect(sheet.name, 'Tâches');
      expect(column.name, 'Budget');
      expect(column.type, ColumnType.number);
      expect(column.width, 150);
      expect(row[column.id], const NumberValue(1234.5));

      // Les nouveautés ont leurs valeurs par défaut…
      expect(column.style, CellStyle.none);
      expect(column.options, isEmpty);
      expect(row.height, isNull);
      expect(row.styles, isEmpty);
      expect(await store.views.getViews(sheet.id), isEmpty);
      expect(column.formula, isEmpty);
      expect(column.calcCells, isEmpty);

      // …et sont utilisables.
      await store.columns.updateColumn(
        column.copyWith(style: const CellStyle(bold: true)),
      );
      await store.rows.setCellStyle(
        row.id,
        column.id,
        const CellStyle(italic: true),
      );
      await store.rows.setRowHeight(row.id, 40);
      await store.views.createView(sheet.id, name: 'Vue', spec: ViewSpec.full);

      expect(
        (await store.columns.getColumns(sheet.id)).single.style,
        const CellStyle(bold: true),
      );
      final saved = (await store.rows.getRows(sheet.id)).single;
      expect(saved.height, 40);
      expect(saved.styles, {column.id: const CellStyle(italic: true)});
      expect(await store.views.getViews(sheet.id), hasLength(1));
    },
  );
}
