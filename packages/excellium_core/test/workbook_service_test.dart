import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_core/memory.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryStore store;
  late WorkbookService service;

  setUp(() {
    store = InMemoryStore();
    service = WorkbookService(store);
  });

  tearDown(() => store.close());

  group('création de feuille', () {
    test('crée les colonnes Texte et les lignes vides par défaut', () async {
      final sheet = await service.createSheet();

      final columns = await store.columns.getColumns(sheet.id);
      final rows = await store.rows.getRows(sheet.id);
      expect(columns, hasLength(WorkbookService.defaultColumnCount));
      expect(columns.every((c) => c.type == ColumnType.text), isTrue);
      expect(columns.map((c) => c.letter).take(3), ['A', 'B', 'C']);
      expect(rows, hasLength(WorkbookService.defaultRowCount));
    });

    test('numérote les feuilles sans nom', () async {
      await service.createSheet();
      await service.createSheet();

      final sheets = await store.sheets.getSheets();
      expect(sheets.map((s) => s.name), ['Feuille 1', 'Feuille 2']);
    });

    test('ne réutilise pas un nom déjà pris', () async {
      await service.createSheet(name: 'Feuille 2');

      final created = await service.createSheet();
      expect(created.name, 'Feuille 3');
    });

    test(
      'ensureDefaultSheet ne crée une feuille que si le classeur est vide',
      () async {
        await service.ensureDefaultSheet();
        await service.ensureDefaultSheet();

        expect(await store.sheets.getSheets(), hasLength(1));
      },
    );
  });

  group('déplacement', () {
    test('déplace une colonne et décale les autres', () async {
      final sheet = await service.createSheet(columnCount: 0, rowCount: 0);
      for (final name in ['A', 'B', 'C', 'D']) {
        await store.columns.addColumn(sheet.id, name: name);
      }

      await service.moveColumn(sheet.id, 0, 2);

      final columns = await store.columns.getColumns(sheet.id);
      expect(columns.map((c) => c.name), ['B', 'C', 'A', 'D']);
    });

    test('les cellules suivent leur colonne', () async {
      final sheet = await service.createSheet(columnCount: 2, rowCount: 1);
      final columns = await store.columns.getColumns(sheet.id);
      final row = (await store.rows.getRows(sheet.id)).single;
      await store.rows.setCell(row.id, columns[0].id, const TextValue('a'));

      await service.moveColumn(sheet.id, 0, 1);

      final moved = await store.columns.getColumns(sheet.id);
      final saved = (await store.rows.getRows(sheet.id)).single;
      expect(moved[1].id, columns[0].id);
      expect(saved[moved[1].id], const TextValue('a'));
    });

    test('un déplacement hors limites ne change rien', () async {
      final sheet = await service.createSheet(columnCount: 2, rowCount: 0);
      final before = await store.columns.getColumns(sheet.id);

      await service.moveColumn(sheet.id, 0, 5);
      await service.moveColumn(sheet.id, -1, 0);

      expect(await store.columns.getColumns(sheet.id), before);
    });

    test('déplace une feuille', () async {
      await service.createSheet(name: 'A');
      await service.createSheet(name: 'B');
      await service.createSheet(name: 'C');

      await service.moveSheet(2, 0);

      final sheets = await store.sheets.getSheets();
      expect(sheets.map((s) => s.name), ['C', 'A', 'B']);
    });
  });

  group('colonne', () {
    late Sheet sheet;
    late ColumnDef column;
    late SheetRow row;

    setUp(() async {
      sheet = await service.createSheet(columnCount: 1, rowCount: 1);
      column = (await store.columns.getColumns(sheet.id)).single;
      row = (await store.rows.getRows(sheet.id)).single;
    });

    Future<ColumnDef> reloadColumn() async =>
        (await store.columns.getColumns(sheet.id)).single;

    Future<SheetRow> reloadRow() async =>
        (await store.rows.getRows(sheet.id)).single;

    test(
      'renommer retire les espaces de bord ; vide rétablit la lettre',
      () async {
        await service.renameColumn(column, '  Budget ');
        expect((await reloadColumn()).label, 'Budget');

        await service.renameColumn(await reloadColumn(), '   ');
        expect((await reloadColumn()).label, 'A');
      },
    );

    test('la largeur est bornée', () async {
      await service.resizeColumn(column, 10);
      expect((await reloadColumn()).width, ColumnDef.minWidth);

      await service.resizeColumn(column, 5000);
      expect((await reloadColumn()).width, ColumnDef.maxWidth);
    });

    test('changer de type convertit les valeurs lisibles', () async {
      await store.rows.setCell(row.id, column.id, const TextValue('12,5'));

      await service.changeColumnType(column, ColumnType.number);

      expect((await reloadColumn()).type, ColumnType.number);
      expect((await reloadRow())[column.id], const NumberValue(12.5));
    });

    test('changer de type efface les valeurs devenues illisibles', () async {
      await store.rows.setCell(row.id, column.id, const TextValue('Import'));

      await service.changeColumnType(column, ColumnType.date);

      expect((await reloadRow()).isEmpty, isTrue);
    });

    test(
      'passer en Référence crée la configuration, en sortir la retire',
      () async {
        await service.changeColumnType(column, ColumnType.reference);
        final asReference = await reloadColumn();
        expect(asReference.reference, const ReferenceConfig());

        await service.changeColumnType(asReference, ColumnType.text);
        expect((await reloadColumn()).reference, isNull);
      },
    );
  });

  group('saisie', () {
    late ColumnDef column;
    late SheetRow row;
    late Sheet sheet;

    setUp(() async {
      sheet = await service.createSheet(columnCount: 1, rowCount: 1);
      column = (await store.columns.getColumns(sheet.id)).single;
      row = (await store.rows.getRows(sheet.id)).single;
    });

    Future<SheetRow> reloadRow() async =>
        (await store.rows.getRows(sheet.id)).single;

    test(
      'une saisie valide est enregistrée dans le type de la colonne',
      () async {
        await service.changeColumnType(column, ColumnType.number);
        final numeric = (await store.columns.getColumns(sheet.id)).single;

        final error = await service.enterText(row, numeric, '1 234,5');

        expect(error, isNull);
        expect((await reloadRow())[column.id], const NumberValue(1234.5));
      },
    );

    test('une saisie refusée laisse la cellule inchangée', () async {
      await service.changeColumnType(column, ColumnType.number);
      final numeric = (await store.columns.getColumns(sheet.id)).single;
      await service.enterText(row, numeric, '10');

      final error = await service.enterText(await reloadRow(), numeric, 'dix');

      expect(error, CellInputError.notANumber);
      expect((await reloadRow())[column.id], const NumberValue(10));
    });

    test('une saisie vide vide la cellule', () async {
      await service.enterText(row, column, 'bonjour');

      await service.enterText(await reloadRow(), column, '');

      expect((await reloadRow()).isEmpty, isTrue);
    });

    test('setValue refuse une valeur incompatible avec la colonne', () async {
      expect(
        () => service.setValue(row, column, const BoolValue(true)),
        throwsArgumentError,
      );
    });
  });
}
