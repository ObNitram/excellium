import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_core/memory.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryStore store;
  late WorkbookService service;
  late DateTime now;
  late Sheet sheet;
  late ColumnDef column;

  Future<SheetRow> firstRow() async =>
      (await store.rows.getRows(sheet.id)).first;

  Future<CellValue?> firstCell() async => (await firstRow())[column.id];

  setUp(() async {
    store = InMemoryStore();
    now = DateTime(2026, 11, 26, 10);
    service = WorkbookService(
      store,
      history: UndoHistory(store, clock: () => now),
    );
    // Le classeur de départ n'entre pas dans l'historique.
    await service.ensureDefaultSheet();
    sheet = (await store.sheets.getSheets()).single;
    column = (await store.columns.getColumns(sheet.id)).first;
  });

  tearDown(() => store.close());

  test('rien à annuler au départ', () async {
    expect(service.history.canUndo, isFalse);
    expect(service.history.canRedo, isFalse);
    expect(await service.undo(), isFalse);
    expect(await service.redo(), isFalse);
  });

  test('annuler puis rétablir une saisie', () async {
    await service.setValue(await firstRow(), column, const TextValue('A'));
    await service.setValue(await firstRow(), column, const TextValue('B'));
    expect(service.history.canUndo, isTrue);

    expect(await service.undo(), isTrue);
    expect(await firstCell(), const TextValue('A'));
    expect(await service.undo(), isTrue);
    expect(await firstCell(), isNull);
    expect(service.history.canUndo, isFalse);

    expect(await service.redo(), isTrue);
    expect(await firstCell(), const TextValue('A'));
    expect(await service.redo(), isTrue);
    expect(await firstCell(), const TextValue('B'));
    expect(service.history.canRedo, isFalse);
  });

  test('une nouvelle modification efface ce qu\'on pouvait rétablir', () async {
    await service.setValue(await firstRow(), column, const TextValue('A'));
    await service.undo();
    expect(service.history.canRedo, isTrue);

    await service.setValue(await firstRow(), column, const TextValue('C'));
    expect(service.history.canRedo, isFalse);
  });

  test('une action composée s\'annule d\'un coup', () async {
    final other = await service.createSheet(name: 'Équipe');
    expect(await store.sheets.getSheets(), hasLength(2));

    await service.undo();
    final sheets = await store.sheets.getSheets();
    expect(sheets.map((s) => s.id), [sheet.id]);
    expect(await store.columns.getColumns(other.id), isEmpty);
  });

  test('une suppression s\'annule, identifiants compris', () async {
    final row = await firstRow();
    await service.setValue(row, column, const TextValue('A'));
    await service.deleteRow(row);
    expect((await firstRow()).id, isNot(row.id));

    await service.undo();
    expect((await firstRow()).id, row.id);
    expect(await firstCell(), const TextValue('A'));
  });

  test('valider une cellule sans la changer n\'entre pas dans '
      'l\'historique', () async {
    await service.setValue(await firstRow(), column, const TextValue('A'));
    await service.undo();
    expect(service.history.canRedo, isTrue);

    await service.enterText(await firstRow(), column, '');
    await service.setValue(await firstRow(), column, null);
    expect(service.history.canUndo, isFalse);
    // Ce qu'on pouvait rétablir l'est toujours.
    expect(service.history.canRedo, isTrue);
  });

  test('une suppression refusée n\'entre pas dans l\'historique', () async {
    expect(await service.deleteSheet(sheet.id), isFalse);
    expect(service.history.canUndo, isFalse);
  });

  test('le style s\'annule', () async {
    await service.styleColumn(column, const CellStyle(bold: true));
    await service.undo();
    expect(
      (await store.columns.getColumns(sheet.id)).first.style,
      CellStyle.none,
    );
  });

  test('une formule tapée lettre par lettre s\'annule d\'un coup', () async {
    for (final text in ['B', 'Bu', 'Bud']) {
      await service.setFormula(column, text);
      now = now.add(const Duration(milliseconds: 300));
    }
    Future<String> formula() async =>
        (await store.columns.getColumns(sheet.id)).first.formula;
    expect(await formula(), 'Bud');

    await service.undo();
    expect(await formula(), '');
    expect(service.history.canUndo, isFalse);
  });

  test('après une pause, la saisie reprend dans une nouvelle étape', () async {
    await service.setFormula(column, 'A');
    now = now.add(const Duration(seconds: 5));
    await service.setFormula(column, 'AB');

    await service.undo();
    expect((await store.columns.getColumns(sheet.id)).first.formula, 'A');
  });

  test('deux cases de calcul différentes ne se fondent pas', () async {
    await service.setCalcCell(column, 0, '=1');
    await service.setCalcCell(column, 1, '=2');

    await service.undo();
    final calc = (await store.columns.getColumns(sheet.id)).first.calcCells;
    expect(calc, {0: '=1'});
  });

  test('l\'historique se limite aux dernières modifications', () async {
    final history = UndoHistory(store, limit: 2);
    final limited = WorkbookService(store, history: history);
    for (final text in ['1', '2', '3']) {
      await limited.setValue(await firstRow(), column, TextValue(text));
    }
    expect(await limited.undo(), isTrue);
    expect(await limited.undo(), isTrue);
    expect(await limited.undo(), isFalse);
    expect(await firstCell(), const TextValue('1'));
  });

  test('changes prévient à chaque étape', () async {
    var count = 0;
    final subscription = service.history.changes.listen((_) => count++);
    await service.setValue(await firstRow(), column, const TextValue('A'));
    await service.undo();
    await service.redo();
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    expect(count, 3);
  });
}
