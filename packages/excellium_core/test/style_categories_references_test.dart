import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_core/memory.dart';
import 'package:test/test.dart';

const sheetId = SheetId('s');

ColumnDef col(
  String id,
  ColumnType type,
  int position, {
  CellStyle style = CellStyle.none,
  List<String> options = const [],
}) => ColumnDef(
  id: ColumnId(id),
  sheetId: sheetId,
  position: position,
  type: type,
  style: style,
  options: options,
);

SheetRow row(
  int position, {
  Map<ColumnId, CellValue> cells = const {},
  Map<ColumnId, CellStyle> styles = const {},
}) => SheetRow(
  id: RowId('r$position'),
  sheetId: sheetId,
  position: position,
  cells: cells,
  styles: styles,
);

void main() {
  group('CellStyle', () {
    test('merge : les propriétés précisées par le second l\'emportent', () {
      const base = CellStyle(bold: true, align: TextAlignment.left);
      const over = CellStyle(bold: false, italic: true);
      expect(
        base.merge(over),
        const CellStyle(bold: false, italic: true, align: TextAlignment.left),
      );
      expect(base.merge(null), base);
    });

    test('without : retire seulement les propriétés précisées', () {
      const style = CellStyle(bold: true, italic: true, underline: false);
      expect(
        style.without(const CellStyle(bold: false, underline: true)),
        const CellStyle(italic: true),
      );
    });

    test('isEmpty', () {
      expect(CellStyle.none.isEmpty, isTrue);
      expect(const CellStyle(bold: false).isEmpty, isFalse);
    });
  });

  group('resolveStyle', () {
    test('valeurs par défaut selon le type', () {
      expect(
        resolveStyle(col('n', ColumnType.number, 0)).align,
        TextAlignment.right,
      );
      expect(
        resolveStyle(col('b', ColumnType.boolean, 0)).align,
        TextAlignment.center,
      );
      final text = resolveStyle(col('t', ColumnType.text, 0));
      expect(text.align, TextAlignment.left);
      expect(text.bold, isFalse);
      expect(text.boolDisplay, BoolDisplay.checkbox);
      expect(text.percentDisplay, PercentDisplay.value);
    });

    test('police, taille, couleurs, bordure et format par défaut', () {
      const column = ColumnDef(
        id: ColumnId('c'),
        sheetId: SheetId('s'),
        position: 0,
        type: ColumnType.number,
      );
      final style = resolveStyle(column);
      expect(style.font, CellFont.sans);
      expect(style.fontSize, CellStyle.defaultFontSize);
      expect(style.textColor, isNull);
      expect(style.fillColor, isNull);
      expect(style.border, CellBorder.none);
      expect(style.wrap, isFalse);
      expect(style.numberFormat, NumberDisplay.automatic);
      expect(style.decimals, isNull);
    });

    test('une cellule peut revenir aux couleurs et décimales par défaut', () {
      const column = ColumnDef(
        id: ColumnId('c'),
        sheetId: SheetId('s'),
        position: 0,
        type: ColumnType.number,
        style: CellStyle(
          textColor: 0xFFB3261E,
          fillColor: 0xFFFFF4CC,
          decimals: 2,
        ),
      );
      expect(resolveStyle(column).decimals, 2);
      final row = SheetRow(
        id: const RowId('r'),
        sheetId: const SheetId('s'),
        position: 0,
        styles: {
          const ColumnId('c'): const CellStyle(
            textColor: 0,
            fillColor: 0,
            decimals: -1,
          ),
        },
      );
      final style = resolveStyle(column, row);
      expect(style.textColor, isNull);
      expect(style.fillColor, isNull);
      expect(style.decimals, isNull);
    });

    test('le style de la cellule complète celui de la colonne', () {
      final column = col(
        'c',
        ColumnType.text,
        0,
        style: const CellStyle(bold: true, align: TextAlignment.center),
      );
      final styled = row(
        0,
        styles: {column.id: const CellStyle(bold: false, italic: true)},
      );
      final resolved = resolveStyle(column, styled);
      expect(resolved.bold, isFalse);
      expect(resolved.italic, isTrue);
      expect(resolved.align, TextAlignment.center);
      expect(resolveStyle(column, row(1)).bold, isTrue);
    });
  });

  group('catégories', () {
    final column = col(
      'c',
      ColumnType.singleCategory,
      0,
      options: ['À faire', 'En cours'],
    );

    test('categoriesOf : définies d\'abord, puis celles des cellules', () {
      final rows = [
        row(0, cells: {column.id: CategoryValue.single('Terminé')}),
        row(1, cells: {column.id: CategoryValue.single('En cours')}),
        row(
          2,
          cells: {
            column.id: CategoryValue(['Bloqué', 'Terminé']),
          },
        ),
      ];
      expect(categoriesOf(column, rows), [
        'À faire',
        'En cours',
        'Terminé',
        'Bloqué',
      ]);
    });

    test('toggleCategory en catégorie unique : remplace, ou vide', () {
      final current = CategoryValue.single('A');
      expect(
        toggleCategory(current, 'B', multiple: false),
        CategoryValue.single('B'),
      );
      expect(toggleCategory(current, 'A', multiple: false), isNull);
      expect(
        toggleCategory(null, 'A', multiple: false),
        CategoryValue.single('A'),
      );
    });

    test('toggleCategory en catégorie multiple : ajoute ou retire', () {
      final current = CategoryValue(['A', 'B']);
      expect(
        toggleCategory(current, 'C', multiple: true),
        CategoryValue(['A', 'B', 'C']),
      );
      expect(
        toggleCategory(current, 'A', multiple: true),
        CategoryValue(['B']),
      );
      expect(toggleCategory(CategoryValue(['A']), 'A', multiple: true), isNull);
    });
  });

  group('références', () {
    final name = col('name', ColumnType.text, 0);
    final team = col('team', ColumnType.text, 1);
    final columns = [name, team];
    final people = [
      row(
        0,
        cells: {
          name.id: const TextValue('Camille Martin'),
          team.id: const TextValue('Design'),
        },
      ),
      row(
        1,
        cells: {
          name.id: const TextValue('Hugo Petit'),
          team.id: const TextValue('Développement'),
        },
      ),
      row(2, cells: {team.id: const TextValue('Design')}),
      row(3),
    ];

    test('rowLabel : première colonne, sinon « Ligne N »', () {
      expect(rowLabel(people[0], columns), 'Camille Martin');
      expect(rowLabel(people[2], columns), 'Ligne 3');
    });

    test('searchRows : cherche dans la première colonne par défaut', () {
      final found = searchRows(
        people,
        columns,
        searchColumnIds: const [],
        query: 'hugo',
      );
      expect(found.map((r) => r.position), [1]);
    });

    test(
      'searchRows : une requête vide liste les lignes qui ont du contenu',
      () {
        final found = searchRows(
          people,
          columns,
          searchColumnIds: const [],
          query: '',
        );
        expect(found.map((r) => r.position), [0, 1]);
      },
    );

    test('searchRows : cherche dans les colonnes choisies', () {
      final found = searchRows(
        people,
        columns,
        searchColumnIds: [name.id, team.id],
        query: 'design',
      );
      expect(found.map((r) => r.position), [0, 2]);
    });

    test('searchRows : respecte la limite', () {
      final found = searchRows(
        people,
        columns,
        searchColumnIds: [team.id],
        query: '',
        limit: 2,
      );
      expect(found, hasLength(2));
    });

    test('searchRows : des colonnes de recherche disparues sont ignorées', () {
      final found = searchRows(
        people,
        columns,
        searchColumnIds: const [ColumnId('supprimée')],
        query: 'camille',
      );
      expect(found.map((r) => r.position), [0]);
    });

    test('toggleReference en 1–n : remplace, ou vide', () {
      final current = ReferenceValue(const [RowId('a')]);
      expect(
        toggleReference(
          current,
          const RowId('b'),
          cardinality: Cardinality.one,
        ),
        ReferenceValue(const [RowId('b')]),
      );
      expect(
        toggleReference(
          current,
          const RowId('a'),
          cardinality: Cardinality.one,
        ),
        isNull,
      );
    });

    test('toggleReference en n–n : ajoute ou retire', () {
      final current = ReferenceValue(const [RowId('a')]);
      expect(
        toggleReference(
          current,
          const RowId('b'),
          cardinality: Cardinality.many,
        ),
        ReferenceValue(const [RowId('a'), RowId('b')]),
      );
      expect(
        toggleReference(
          current,
          const RowId('a'),
          cardinality: Cardinality.many,
        ),
        isNull,
      );
    });
  });

  group('vues', () {
    test('la vue complète est une grille sans critère', () {
      expect(ViewSpec.full.isFull, isTrue);
      expect(ViewSpec(layout: const ViewLayout.kanban()).isFull, isFalse);
      expect(ViewSpec(hiddenColumnIds: const [ColumnId('c')]).isFull, isFalse);
    });

    test('normalized ignore les filtres vides', () {
      final withEmptyFilter = ViewSpec(
        query: RowQuery(
          filters: {const ColumnId('c'): const TextContains('  ')},
        ),
      );
      expect(withEmptyFilter == ViewSpec.full, isFalse);
      expect(withEmptyFilter.normalized, ViewSpec.full);
      expect(withEmptyFilter.isFull, isTrue);
    });
  });

  group('WorkbookService', () {
    late InMemoryStore store;
    late WorkbookService service;
    late Sheet sheet;

    setUp(() async {
      store = InMemoryStore();
      service = WorkbookService(store);
      sheet = await service.createSheet(columnCount: 1, rowCount: 2);
    });

    tearDown(() => store.close());

    Future<ColumnDef> column() async =>
        (await store.columns.getColumns(sheet.id)).single;

    Future<List<SheetRow>> rows() => store.rows.getRows(sheet.id);

    test('styleCell ne touche que la cellule visée', () async {
      final c = await column();
      final all = await rows();

      await service.styleCell(all[0], c, const CellStyle(bold: true));

      final after = await rows();
      expect(resolveStyle(c, after[0]).bold, isTrue);
      expect(resolveStyle(c, after[1]).bold, isFalse);
    });

    test('styleCell cumule les réglages successifs', () async {
      final c = await column();
      await service.styleCell(
        (await rows())[0],
        c,
        const CellStyle(bold: true),
      );
      await service.styleCell(
        (await rows())[0],
        c,
        const CellStyle(italic: true),
      );

      expect(
        (await rows())[0].styles[c.id],
        const CellStyle(bold: true, italic: true),
      );
    });

    test('styleColumn s\'applique à toute la colonne et remplace les réglages '
        'individuels de la même propriété', () async {
      final c = await column();
      await service.styleCell(
        (await rows())[0],
        c,
        const CellStyle(bold: false, italic: true),
      );

      await service.styleColumn(c, const CellStyle(bold: true));

      final styled = await column();
      final after = await rows();
      expect(resolveStyle(styled, after[0]).bold, isTrue);
      expect(resolveStyle(styled, after[1]).bold, isTrue);
      // L'italique individuel, non concerné, est conservé.
      expect(after[0].styles[c.id], const CellStyle(italic: true));
    });

    test(
      'toggleCellCategory enregistre la nouvelle catégorie sur la colonne',
      () async {
        await service.changeColumnType(
          await column(),
          ColumnType.multiCategory,
        );
        await service.toggleCellCategory(
          (await rows())[0],
          await column(),
          ' Urgent ',
        );
        await service.toggleCellCategory(
          (await rows())[0],
          await column(),
          'Client',
        );

        final c = await column();
        expect(c.options, ['Urgent', 'Client']);
        expect((await rows())[0][c.id], CategoryValue(['Urgent', 'Client']));

        await service.toggleCellCategory((await rows())[0], c, 'Urgent');
        expect((await rows())[0][c.id], CategoryValue(['Client']));
        expect((await column()).options, ['Urgent', 'Client']);
      },
    );

    test('resizeRow borne la hauteur', () async {
      final first = (await rows())[0];
      await service.resizeRow(first, 5);
      expect((await rows())[0].height, SheetRow.minHeight);
      await service.resizeRow(first, 900);
      expect((await rows())[0].height, SheetRow.maxHeight);
      await service.resizeRow(first, null);
      expect((await rows())[0].height, isNull);
    });

    test(
      'saveView numérote les vues sans nom et normalise les critères',
      () async {
        final c = await column();
        final spec = ViewSpec(
          query: RowQuery(
            sort: SortSpec(c.id),
            filters: {c.id: const TextContains('')},
          ),
        );

        final first = await service.saveView(sheet.id, spec);
        final second = await service.saveView(sheet.id, spec, name: ' Suivi ');
        final third = await service.saveView(sheet.id, spec);

        expect(first.name, 'Vue 1');
        expect(second.name, 'Suivi');
        expect(third.name, 'Vue 3');
        expect(first.spec.query.filters, isEmpty);
        expect(first.spec.query.sort, SortSpec(c.id));
      },
    );
  });
}
