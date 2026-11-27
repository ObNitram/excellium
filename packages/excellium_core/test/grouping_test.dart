import 'package:excellium_core/excellium_core.dart';
import 'package:test/test.dart';

void main() {
  const sheetId = SheetId('s');

  SheetRow row(int position, [Map<ColumnId, CellValue> cells = const {}]) =>
      SheetRow(
        id: RowId('r$position'),
        sheetId: sheetId,
        position: position,
        cells: cells,
      );

  const title = ColumnId('titre');
  const status = ColumnDef(
    id: ColumnId('statut'),
    sheetId: sheetId,
    position: 1,
    name: 'Statut',
    type: ColumnType.singleCategory,
    options: ['À faire', 'En cours', 'Terminé'],
  );
  const tags = ColumnDef(
    id: ColumnId('tags'),
    sheetId: sheetId,
    position: 2,
    type: ColumnType.multiCategory,
  );
  const owner = ColumnDef(
    id: ColumnId('resp'),
    sheetId: sheetId,
    position: 3,
    type: ColumnType.reference,
  );

  final rows = [
    row(0, {
      title: const TextValue('Maquette'),
      status.id: CategoryValue.single('En cours'),
      tags.id: CategoryValue(['Design', 'Urgent']),
      owner.id: ReferenceValue([const RowId('p2')]),
    }),
    row(1, {
      title: const TextValue('Import'),
      status.id: CategoryValue.single('À faire'),
      tags.id: CategoryValue(['Technique']),
      owner.id: ReferenceValue([const RowId('p1'), const RowId('p2')]),
    }),
    row(2, {
      title: const TextValue('Atelier'),
      status.id: CategoryValue.single('En cours'),
    }),
    row(3, {title: const TextValue('Sans statut')}),
    row(4),
  ];

  List<String> titles(RowGroup group) => [
    for (final r in group.rows) (r[title] as TextValue).text,
  ];

  test('seules les colonnes Catégorie et Référence se regroupent', () {
    expect(canGroupBy(ColumnType.singleCategory), isTrue);
    expect(canGroupBy(ColumnType.multiCategory), isTrue);
    expect(canGroupBy(ColumnType.reference), isTrue);
    expect(canGroupBy(ColumnType.text), isFalse);
    expect(canGroupBy(ColumnType.formula), isFalse);
  });

  test(
    'catégorie unique : l\'ordre des catégories, puis les lignes sans valeur',
    () {
      final groups = groupRows(column: status, shown: rows, all: rows);

      expect(groups.map((g) => g.category), [
        'À faire',
        'En cours',
        'Terminé',
        null,
      ]);
      expect(titles(groups[0]), ['Import']);
      expect(titles(groups[1]), ['Maquette', 'Atelier']);
      expect(groups[2].rows, isEmpty);
      expect(groups[3].isNone, isTrue);
      // La ligne entièrement vide n'entre dans aucun groupe.
      expect(titles(groups[3]), ['Sans statut']);
    },
  );

  test('un filtre actif masque les groupes qu\'il vide', () {
    final groups = groupRows(
      column: status,
      shown: [rows[1]],
      all: rows,
      hideEmpty: true,
    );

    expect(groups.map((g) => g.category), ['À faire']);
  });

  test('les lignes d\'un groupe gardent l\'ordre de la vue', () {
    final groups = groupRows(
      column: status,
      shown: [rows[2], rows[0], rows[1]],
      all: rows,
    );

    expect(titles(groups[1]), ['Atelier', 'Maquette']);
  });

  test(
    'catégorie multiple : une ligne apparaît dans chacun de ses groupes',
    () {
      final groups = groupRows(column: tags, shown: rows, all: rows);

      expect(groups.map((g) => g.category), [
        'Design',
        'Urgent',
        'Technique',
        null,
      ]);
      expect(titles(groups[0]), ['Maquette']);
      expect(titles(groups[1]), ['Maquette']);
      expect(titles(groups[3]), ['Atelier', 'Sans statut']);
    },
  );

  test('référence : l\'ordre de la feuille liée, relation n – n comprise', () {
    final groups = groupRows(
      column: owner,
      shown: rows,
      all: rows,
      referenceOrder: const [RowId('p1'), RowId('p2'), RowId('p3')],
    );

    expect(groups.map((g) => g.reference), [
      const RowId('p1'),
      const RowId('p2'),
      null,
    ]);
    expect(titles(groups[0]), ['Import']);
    expect(titles(groups[1]), ['Maquette', 'Import']);
  });

  test('une référence vers une ligne disparue reste à la fin', () {
    final groups = groupRows(
      column: owner,
      shown: rows,
      all: rows,
      referenceOrder: const [RowId('p2')],
    );

    expect(groups.map((g) => g.reference), [
      const RowId('p2'),
      const RowId('p1'),
      null,
    ]);
  });

  test('la valeur d\'un groupe sert à y ajouter une ligne', () {
    final byStatus = groupRows(column: status, shown: rows, all: rows);
    final byTags = groupRows(column: tags, shown: rows, all: rows);
    final byOwner = groupRows(column: owner, shown: rows, all: rows);

    expect(byStatus.first.valueFor(status), CategoryValue.single('À faire'));
    expect(byTags.first.valueFor(tags), CategoryValue(['Design']));
    expect(byOwner.first.valueFor(owner), ReferenceValue([const RowId('p2')]));
    expect(byStatus.last.valueFor(status), isNull);
  });

  test('chaque groupe a une clé stable et distincte', () {
    final groups = groupRows(column: status, shown: rows, all: rows);

    expect(groups.map((g) => g.key).toSet(), hasLength(groups.length));
    expect(groups.last.key, '');
  });

  test('la vue sans une colonne perd son regroupement sur cette colonne', () {
    final spec = ViewSpec(groupBy: status.id);

    expect(spec.isFull, isFalse);
    expect(spec.withoutColumn(status.id).isFull, isTrue);
    expect(spec.withoutColumn(tags.id).groupBy, status.id);
    expect(spec.copyWith(clearGroupBy: true).groupBy, isNull);
    expect(spec.normalized, spec);
    expect(ViewSpec(groupBy: status.id) == ViewSpec(groupBy: tags.id), isFalse);
  });
}
