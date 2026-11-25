/// Suite de tests de contrat d'un [ExcelliumStore].
///
/// Tout moteur de stockage doit la réussir. Pour brancher un nouveau moteur,
/// on écrit son implémentation des interfaces puis on appelle
/// [runStoreContractTests] depuis ses tests.
library;

import 'dart:async';

import 'package:excellium_core/excellium_core.dart';
import 'package:test/test.dart';

/// Déclare les tests de contrat pour le moteur ouvert par [open].
///
/// [open] doit renvoyer à chaque appel un stockage vide et indépendant.
void runStoreContractTests(
  String engine,
  FutureOr<ExcelliumStore> Function() open,
) {
  group('contrat de stockage — $engine', () {
    late ExcelliumStore store;

    setUp(() async => store = await open());
    tearDown(() => store.close());

    group('feuilles', () {
      test('une feuille créée se place en dernière position', () async {
        final a = await store.sheets.createSheet(name: 'A');
        final b = await store.sheets.createSheet(name: 'B');

        final sheets = await store.sheets.getSheets();
        expect(sheets.map((s) => s.id), [a.id, b.id]);
        expect(sheets.map((s) => s.position), [0, 1]);
        expect(sheets.map((s) => s.name), ['A', 'B']);
      });

      test('renommer et réordonner', () async {
        final a = await store.sheets.createSheet(name: 'A');
        final b = await store.sheets.createSheet(name: 'B');
        final c = await store.sheets.createSheet(name: 'C');

        await store.sheets.renameSheet(b.id, 'Clients');
        await store.sheets.reorderSheets([c.id, a.id, b.id]);

        final sheets = await store.sheets.getSheets();
        expect(sheets.map((s) => s.name), ['C', 'A', 'Clients']);
        expect(sheets.map((s) => s.position), [0, 1, 2]);
      });

      test(
        'supprimer une feuille supprime son contenu et resserre les rangs',
        () async {
          final a = await store.sheets.createSheet(name: 'A');
          final b = await store.sheets.createSheet(name: 'B');
          final column = await store.columns.addColumn(a.id);
          final row = await store.rows.addRow(a.id);
          await store.rows.setCell(row.id, column.id, const TextValue('x'));

          await store.sheets.deleteSheet(a.id);

          final sheets = await store.sheets.getSheets();
          expect(sheets.map((s) => s.id), [b.id]);
          expect(sheets.single.position, 0);
          expect(await store.columns.getColumns(a.id), isEmpty);
          expect(await store.rows.getRows(a.id), isEmpty);
        },
      );
    });

    group('colonnes', () {
      late Sheet sheet;

      setUp(() async => sheet = await store.sheets.createSheet(name: 'S'));

      test(
        'une colonne ajoutée est de type Texte, en dernière position',
        () async {
          final first = await store.columns.addColumn(sheet.id);
          final second = await store.columns.addColumn(
            sheet.id,
            name: 'Budget',
            type: ColumnType.number,
          );

          final columns = await store.columns.getColumns(sheet.id);
          expect(columns.map((c) => c.id), [first.id, second.id]);
          expect(columns.map((c) => c.position), [0, 1]);
          expect(columns[0].type, ColumnType.text);
          expect(columns[0].name, '');
          expect(columns[1].type, ColumnType.number);
          expect(columns[1].name, 'Budget');
        },
      );

      test('modifier le nom, le type, la largeur et la référence', () async {
        final target = await store.sheets.createSheet(name: 'Cible');
        final searched = await store.columns.addColumn(target.id);
        final column = await store.columns.addColumn(sheet.id);

        await store.columns.updateColumn(
          column.copyWith(
            name: 'Responsable',
            type: ColumnType.reference,
            width: 200,
            reference: ReferenceConfig(
              targetSheetId: target.id,
              cardinality: Cardinality.many,
              searchColumnIds: [searched.id],
            ),
          ),
        );

        final saved = (await store.columns.getColumns(sheet.id)).single;
        expect(saved.name, 'Responsable');
        expect(saved.type, ColumnType.reference);
        expect(saved.width, 200);
        expect(saved.reference?.targetSheetId, target.id);
        expect(saved.reference?.cardinality, Cardinality.many);
        expect(saved.reference?.searchColumnIds, [searched.id]);
        expect(saved.position, column.position);
      });

      test('réordonner les colonnes', () async {
        final a = await store.columns.addColumn(sheet.id, name: 'A');
        final b = await store.columns.addColumn(sheet.id, name: 'B');
        final c = await store.columns.addColumn(sheet.id, name: 'C');

        await store.columns.reorderColumns(sheet.id, [b.id, c.id, a.id]);

        final columns = await store.columns.getColumns(sheet.id);
        expect(columns.map((x) => x.name), ['B', 'C', 'A']);
        expect(columns.map((x) => x.position), [0, 1, 2]);
      });

      test(
        'supprimer une colonne efface ses cellules et resserre les rangs',
        () async {
          final a = await store.columns.addColumn(sheet.id, name: 'A');
          final b = await store.columns.addColumn(sheet.id, name: 'B');
          final row = await store.rows.addRow(sheet.id);
          await store.rows.setCell(row.id, a.id, const TextValue('a'));
          await store.rows.setCell(row.id, b.id, const TextValue('b'));

          await store.columns.deleteColumn(a.id);

          final columns = await store.columns.getColumns(sheet.id);
          expect(columns.map((x) => x.name), ['B']);
          expect(columns.single.position, 0);
          final saved = (await store.rows.getRows(sheet.id)).single;
          expect(saved.cells, {b.id: const TextValue('b')});
        },
      );

      test('les colonnes sont propres à chaque feuille', () async {
        final other = await store.sheets.createSheet(name: 'Autre');
        await store.columns.addColumn(sheet.id);
        await store.columns.addColumn(other.id);
        await store.columns.addColumn(other.id);

        expect(await store.columns.getColumns(sheet.id), hasLength(1));
        expect(await store.columns.getColumns(other.id), hasLength(2));
      });
    });

    group('lignes et cellules', () {
      late Sheet sheet;
      late ColumnDef column;

      setUp(() async {
        sheet = await store.sheets.createSheet(name: 'S');
        column = await store.columns.addColumn(sheet.id);
      });

      test('une ligne ajoutée est vide, en dernière position', () async {
        final first = await store.rows.addRow(sheet.id);
        final second = await store.rows.addRow(sheet.id);

        final rows = await store.rows.getRows(sheet.id);
        expect(rows.map((r) => r.id), [first.id, second.id]);
        expect(rows.map((r) => r.position), [0, 1]);
        expect(rows.every((r) => r.isEmpty), isTrue);
      });

      test('chaque type de valeur est relu à l\'identique', () async {
        final values = <CellValue>[
          const TextValue('Maquette « accueil »'),
          const NumberValue(1234.5),
          const NumberValue(-0.25),
          DateValue(2026, 12, 4),
          const DurationValue(Duration(hours: 6, minutes: 30)),
          CategoryValue.single('En cours'),
          CategoryValue(['Design', 'Urgent']),
          const BoolValue(true),
          const BoolValue(false),
          ReferenceValue(const [RowId('r1'), RowId('r2')]),
        ];
        final rows = <SheetRow>[];
        for (final value in values) {
          final row = await store.rows.addRow(sheet.id);
          await store.rows.setCell(row.id, column.id, value);
          rows.add(row);
        }

        final saved = await store.rows.getRows(sheet.id);
        expect([for (final row in saved) row[column.id]], values);
      });

      test('écrire remplace la valeur, écrire null vide la cellule', () async {
        final row = await store.rows.addRow(sheet.id);

        await store.rows.setCell(row.id, column.id, const TextValue('un'));
        await store.rows.setCell(row.id, column.id, const TextValue('deux'));
        expect(
          (await store.rows.getRows(sheet.id)).single[column.id],
          const TextValue('deux'),
        );

        await store.rows.setCell(row.id, column.id, null);
        expect((await store.rows.getRows(sheet.id)).single.isEmpty, isTrue);
      });

      test('supprimer une ligne resserre les rangs', () async {
        final a = await store.rows.addRow(sheet.id);
        final b = await store.rows.addRow(sheet.id);
        final c = await store.rows.addRow(sheet.id);

        await store.rows.deleteRow(b.id);

        final rows = await store.rows.getRows(sheet.id);
        expect(rows.map((r) => r.id), [a.id, c.id]);
        expect(rows.map((r) => r.position), [0, 1]);
      });
    });

    group('flux', () {
      test('watchSheets émet l\'état courant puis les changements', () async {
        await store.sheets.createSheet(name: 'A');

        final names = store.sheets.watchSheets().map(
          (sheets) => sheets.map((s) => s.name).toList(),
        );
        final seen = expectLater(names, emitsThrough(equals(['A', 'B'])));
        await store.sheets.createSheet(name: 'B');
        await seen;
      });

      test('watchRows émet après l\'écriture d\'une cellule', () async {
        final sheet = await store.sheets.createSheet(name: 'S');
        final column = await store.columns.addColumn(sheet.id);
        final row = await store.rows.addRow(sheet.id);

        final values = store.rows
            .watchRows(sheet.id)
            .map((rows) => rows.isEmpty ? null : rows.single[column.id]);
        final seen = expectLater(values, emitsThrough(const NumberValue(42)));
        await store.rows.setCell(row.id, column.id, const NumberValue(42));
        await seen;
      });

      test('watchColumns émet après un changement de colonne', () async {
        final sheet = await store.sheets.createSheet(name: 'S');
        final column = await store.columns.addColumn(sheet.id);

        final names = store.columns
            .watchColumns(sheet.id)
            .map((columns) => columns.map((c) => c.name).toList());
        final seen = expectLater(names, emitsThrough(equals(['Statut'])));
        await store.columns.updateColumn(column.copyWith(name: 'Statut'));
        await seen;
      });
    });

    group('transaction', () {
      test('tout est enregistré quand l\'action réussit', () async {
        final sheet = await store.transaction(() async {
          final created = await store.sheets.createSheet(name: 'S');
          await store.columns.addColumn(created.id);
          await store.rows.addRow(created.id);
          return created;
        });

        expect(await store.sheets.getSheets(), hasLength(1));
        expect(await store.columns.getColumns(sheet.id), hasLength(1));
        expect(await store.rows.getRows(sheet.id), hasLength(1));
      });

      test('rien n\'est enregistré quand l\'action échoue', () async {
        await store.sheets.createSheet(name: 'Avant');

        await expectLater(
          store.transaction(() async {
            await store.sheets.createSheet(name: 'Pendant');
            throw StateError('échec volontaire');
          }),
          throwsStateError,
        );

        final sheets = await store.sheets.getSheets();
        expect(sheets.map((s) => s.name), ['Avant']);
      });
    });
  });
}
