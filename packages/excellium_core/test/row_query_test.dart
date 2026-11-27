import 'package:excellium_core/excellium_core.dart';
import 'package:test/test.dart';

const sheetId = SheetId('s');

ColumnDef col(String id, ColumnType type, int position) => ColumnDef(
  id: ColumnId(id),
  sheetId: sheetId,
  position: position,
  type: type,
);

final title = col('title', ColumnType.text, 0);
final budget = col('budget', ColumnType.number, 1);
final status = col('status', ColumnType.singleCategory, 2);
final tags = col('tags', ColumnType.multiCategory, 3);
final done = col('done', ColumnType.boolean, 4);
final due = col('due', ColumnType.date, 5);
final time = col('time', ColumnType.duration, 6);
final owner = col('owner', ColumnType.reference, 7);

final columns = [title, budget, status, tags, done, due, time, owner];

SheetRow row(int position, Map<ColumnDef, CellValue> cells) => SheetRow(
  id: RowId('r$position'),
  sheetId: sheetId,
  position: position,
  cells: {for (final entry in cells.entries) entry.key.id: entry.value},
);

final rows = [
  row(0, {
    title: const TextValue('Maquette'),
    budget: const NumberValue(1200),
    status: CategoryValue.single('En cours'),
    tags: CategoryValue(['Design', 'Urgent']),
    done: const BoolValue(true),
    due: DateValue(2026, 12, 4),
    time: const DurationValue(Duration(hours: 6, minutes: 30)),
    owner: ReferenceValue([const RowId('camille')]),
  }),
  row(1, {
    title: const TextValue('Import CSV'),
    budget: const NumberValue(850),
    status: CategoryValue.single('À faire'),
    tags: CategoryValue(['Technique']),
    due: DateValue(2026, 12, 11),
    time: const DurationValue(Duration(hours: 4)),
    owner: ReferenceValue([const RowId('hugo')]),
  }),
  row(2, {
    title: const TextValue('atelier client'),
    budget: const NumberValue(600),
    status: CategoryValue.single('Terminé'),
    tags: CategoryValue(['Client']),
    done: const BoolValue(true),
    due: DateValue(2026, 11, 27),
    time: const DurationValue(Duration(hours: 3)),
  }),
  row(3, {title: const TextValue('Sans budget')}),
  row(4, const {}),
];

List<int> positions(RowQuery query) => [
  for (final r in applyRowQuery(rows, columns, query)) r.position,
];

RowQuery filter(ColumnDef column, FilterSpec spec) =>
    RowQuery(filters: {column.id: spec});

void main() {
  test('sans tri ni filtre : toutes les lignes dans leur ordre', () {
    expect(positions(RowQuery.none), [0, 1, 2, 3, 4]);
  });

  test('remet les lignes dans l\'ordre de leur rang', () {
    final shuffled = [rows[3], rows[0], rows[4], rows[2], rows[1]];
    final result = applyRowQuery(shuffled, columns, RowQuery.none);
    expect(result.map((r) => r.position), [0, 1, 2, 3, 4]);
  });

  group('filtres', () {
    test('texte : contient, sans tenir compte de la casse', () {
      expect(positions(filter(title, const TextContains('CLIENT'))), [2]);
      expect(positions(filter(title, const TextContains('a'))), [0, 2, 3]);
    });

    test('nombre : minimum, maximum ou les deux, bornes incluses', () {
      expect(positions(filter(budget, const NumberRange(min: 850))), [0, 1]);
      expect(positions(filter(budget, const NumberRange(max: 850))), [1, 2]);
      expect(
        positions(filter(budget, const NumberRange(min: 601, max: 1199))),
        [1],
      );
    });

    test('date : bornes incluses', () {
      expect(
        positions(
          filter(
            due,
            DateRange(
              from: DateValue(2026, 12, 4),
              to: DateValue(2026, 12, 11),
            ),
          ),
        ),
        [0, 1],
      );
      expect(positions(filter(due, DateRange(to: DateValue(2026, 11, 30)))), [
        2,
      ]);
    });

    test('durée : minimum et maximum', () {
      expect(
        positions(filter(time, const DurationRange(min: Duration(hours: 4)))),
        [0, 1],
      );
    });

    test('catégorie : au moins une des valeurs demandées', () {
      expect(
        positions(filter(status, CategoryAnyOf(['En cours', 'À faire']))),
        [0, 1],
      );
      expect(positions(filter(tags, CategoryAnyOf(['Urgent', 'Client']))), [
        0,
        2,
      ]);
    });

    test('booléen : une cellule vide compte comme faux', () {
      expect(positions(filter(done, const BoolIs(true))), [0, 2]);
      expect(positions(filter(done, const BoolIs(false))), [1, 3]);
    });

    test('référence : pointe vers une des lignes demandées', () {
      expect(positions(filter(owner, ReferenceAnyOf([const RowId('hugo')]))), [
        1,
      ]);
    });

    test('plusieurs filtres se cumulent', () {
      final query = RowQuery(
        filters: {
          status.id: CategoryAnyOf(['En cours', 'À faire']),
          budget.id: const NumberRange(min: 1000),
        },
      );
      expect(positions(query), [0]);
    });

    test('un filtre actif masque les lignes entièrement vides', () {
      expect(positions(filter(done, const BoolIs(false))), isNot(contains(4)));
    });

    test('un filtre vide ne masque rien', () {
      expect(positions(filter(title, const TextContains('  '))), [
        0,
        1,
        2,
        3,
        4,
      ]);
      expect(positions(filter(status, CategoryAnyOf(const []))), hasLength(5));
    });

    test('un filtre sur une colonne inconnue est ignoré', () {
      final query = RowQuery(
        filters: {const ColumnId('supprimée'): const TextContains('x')},
      );
      expect(positions(query), [0, 1, 2, 3, 4]);
    });
  });

  group('tri', () {
    test('nombre croissant : les cellules vides vont à la fin', () {
      expect(positions(RowQuery(sort: SortSpec(budget.id))), [2, 1, 0, 3, 4]);
    });

    test('nombre décroissant : les cellules vides restent à la fin', () {
      expect(positions(RowQuery(sort: SortSpec(budget.id, ascending: false))), [
        0,
        1,
        2,
        3,
        4,
      ]);
    });

    test('texte : sans tenir compte de la casse', () {
      expect(positions(RowQuery(sort: SortSpec(title.id))), [2, 1, 0, 3, 4]);
    });

    test('date et durée : ordre chronologique', () {
      expect(positions(RowQuery(sort: SortSpec(due.id))), [2, 0, 1, 3, 4]);
      expect(positions(RowQuery(sort: SortSpec(time.id))), [2, 1, 0, 3, 4]);
    });

    test(
      'booléen : faux avant vrai, seules les lignes vides vont à la fin',
      () {
        expect(positions(RowQuery(sort: SortSpec(done.id))), [1, 3, 0, 2, 4]);
      },
    );

    test('référence : trie par le libellé fourni', () {
      final result = applyRowQuery(
        rows,
        columns,
        RowQuery(sort: SortSpec(owner.id)),
        referenceLabel: (id) => id == const RowId('hugo') ? 'Alba' : 'Zoé',
      );
      expect(result.map((r) => r.position).take(2), [1, 0]);
    });

    test('à égalité, l\'ordre des rangs est conservé', () {
      final tied = [
        row(0, {budget: const NumberValue(5)}),
        row(1, {budget: const NumberValue(5)}),
        row(2, {budget: const NumberValue(1)}),
      ];
      final result = applyRowQuery(
        tied,
        columns,
        RowQuery(sort: SortSpec(budget.id, ascending: false)),
      );
      expect(result.map((r) => r.position), [0, 1, 2]);
    });

    test('tri et filtre ensemble', () {
      final query = RowQuery(
        sort: SortSpec(due.id),
        filters: {
          status.id: CategoryAnyOf(['En cours', 'À faire', 'Terminé']),
        },
      );
      expect(positions(query), [2, 0, 1]);
    });
  });

  test('les lignes d\'origine ne sont pas modifiées', () {
    final before = List.of(rows);
    applyRowQuery(rows, columns, RowQuery(sort: SortSpec(budget.id)));
    expect(rows, before);
  });
}
