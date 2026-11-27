import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_core/memory.dart';
import 'package:test/test.dart';

/// Suppressions, renommage de feuille et créations depuis un affichage.
void main() {
  late InMemoryStore store;
  late WorkbookService service;
  late Sheet team;
  late Sheet tasks;

  Future<List<ColumnDef>> columns(Sheet sheet) =>
      store.columns.getColumns(sheet.id);
  Future<List<SheetRow>> rows(Sheet sheet) => store.rows.getRows(sheet.id);

  /// « Équipe » (Nom, Pôle ; 2 personnes) et « Tâches » (Titre, Statut,
  /// Responsable → Équipe ; 2 tâches, 1 ligne vide).
  setUp(() async {
    store = InMemoryStore();
    service = WorkbookService(store);

    team = await service.createSheet(
      name: 'Équipe',
      columnCount: 2,
      rowCount: 2,
    );
    final teamColumns = await columns(team);
    final people = await rows(team);
    await store.rows.setCell(
      people[0].id,
      teamColumns[0].id,
      const TextValue('Camille'),
    );
    await store.rows.setCell(
      people[1].id,
      teamColumns[0].id,
      const TextValue('Hugo'),
    );

    tasks = await service.createSheet(
      name: 'Tâches',
      columnCount: 3,
      rowCount: 3,
    );
    var cols = await columns(tasks);
    await service.changeColumnType(cols[1], ColumnType.singleCategory);
    await service.changeColumnType(cols[2], ColumnType.reference);
    cols = await columns(tasks);
    await service.configureReference(
      cols[2],
      ReferenceConfig(
        targetSheetId: team.id,
        cardinality: Cardinality.many,
        searchColumnIds: [teamColumns[0].id, teamColumns[1].id],
      ),
    );
    await service.reorderCategories(cols[1], ['À faire', 'Terminé']);
    final taskRows = await rows(tasks);
    await store.rows.setCell(
      taskRows[0].id,
      cols[0].id,
      const TextValue('Maquette'),
    );
    await store.rows.setCell(
      taskRows[0].id,
      cols[1].id,
      CategoryValue.single('À faire'),
    );
    await store.rows.setCell(
      taskRows[0].id,
      cols[2].id,
      ReferenceValue([people[0].id, people[1].id]),
    );
    await store.rows.setCell(
      taskRows[1].id,
      cols[0].id,
      const TextValue('Import'),
    );
    await store.rows.setCell(
      taskRows[1].id,
      cols[2].id,
      ReferenceValue([people[1].id]),
    );
  });

  tearDown(() => store.close());

  group('feuille', () {
    test('renommer enlève les espaces autour du nom', () async {
      await service.renameSheet(tasks, '  Projets ');

      expect((await store.sheets.getSheets()).last.name, 'Projets');
    });

    test('un nom vide est refusé', () async {
      await service.renameSheet(tasks, '   ');

      expect((await store.sheets.getSheets()).last.name, 'Tâches');
    });

    test('supprimer retire la feuille et son contenu', () async {
      expect(await service.deleteSheet(tasks.id), isTrue);

      expect((await store.sheets.getSheets()).map((s) => s.name), ['Équipe']);
      expect(await columns(tasks), isEmpty);
      expect(await rows(tasks), isEmpty);
    });

    test('la dernière feuille ne se supprime pas', () async {
      await service.deleteSheet(tasks.id);

      expect(await service.deleteSheet(team.id), isFalse);
      expect(await store.sheets.getSheets(), hasLength(1));
    });

    test('les références vers la feuille supprimée sont vidées', () async {
      await service.deleteSheet(team.id);

      final reference = (await columns(tasks))[2];
      expect(reference.type, ColumnType.reference);
      expect(reference.reference?.targetSheetId, isNull);
      expect(reference.reference?.searchColumnIds, isEmpty);
      // La relation n – n choisie est conservée.
      expect(reference.reference?.cardinality, Cardinality.many);
      for (final row in await rows(tasks)) {
        expect(row[reference.id], isNull);
      }
      // Le reste de la feuille est intact.
      expect(
        (await rows(tasks))[0][(await columns(tasks))[0].id],
        const TextValue('Maquette'),
      );
    });
  });

  group('colonne', () {
    test('supprimer retire la colonne et ses cellules', () async {
      final status = (await columns(tasks))[1];

      expect(await service.deleteColumn(status), isTrue);

      final left = await columns(tasks);
      expect(left.map((c) => c.type), [ColumnType.text, ColumnType.reference]);
      expect(left.map((c) => c.position), [0, 1]);
      expect((await rows(tasks))[0].cells.containsKey(status.id), isFalse);
    });

    test('la dernière colonne ne se supprime pas', () async {
      final cols = await columns(team);
      expect(await service.deleteColumn(cols[0]), isTrue);

      expect(await service.deleteColumn(cols[1]), isFalse);
      expect(await columns(team), hasLength(1));
    });

    test('elle sort des colonnes de recherche des références', () async {
      final pole = (await columns(team))[1];

      await service.deleteColumn(pole);

      final reference = (await columns(tasks))[2].reference!;
      expect(reference.searchColumnIds, [(await columns(team))[0].id]);
      expect(reference.targetSheetId, team.id);
    });

    test('elle sort des vues enregistrées de la feuille', () async {
      final cols = await columns(tasks);
      final status = cols[1];
      await service.saveView(
        tasks.id,
        ViewSpec(
          layout: ViewLayout.kanban(status.id),
          query: RowQuery(
            sort: SortSpec(status.id, ascending: true),
            filters: {
              status.id: CategoryAnyOf(['À faire']),
              cols[0].id: const TextContains('a'),
            },
          ),
          hiddenColumnIds: [status.id, cols[2].id],
        ),
        name: 'Suivi',
      );
      await service.saveView(tasks.id, ViewSpec.full, name: 'Tout');

      await service.deleteColumn(status);

      final views = await store.views.getViews(tasks.id);
      expect(views.map((v) => v.name), ['Suivi', 'Tout']);
      final spec = views.first.spec;
      expect(spec.layout, const ViewLayout.kanban());
      expect(spec.query.sort, isNull);
      expect(spec.query.filters.keys, [cols[0].id]);
      expect(spec.hiddenColumnIds, {cols[2].id});
      expect(views.last.spec, ViewSpec.full);
    });
  });

  group('ligne', () {
    test('supprimer retire la ligne et resserre les rangs', () async {
      final before = await rows(tasks);

      await service.deleteRow(before[0]);

      final after = await rows(tasks);
      expect(after.map((r) => r.id), [before[1].id, before[2].id]);
      expect(after.map((r) => r.position), [0, 1]);
    });

    test('elle sort des cellules Référence qui la visaient', () async {
      final people = await rows(team);
      final reference = (await columns(tasks))[2];

      await service.deleteRow(people[1]);

      final after = await rows(tasks);
      // Il restait une autre référence : elle est gardée.
      expect(after[0][reference.id], ReferenceValue([people[0].id]));
      // C'était la seule : la cellule est vidée.
      expect(after[1][reference.id], isNull);
    });
  });

  group('création depuis un affichage', () {
    test(
      'une ligne créée avec des valeurs prend la première ligne vide',
      () async {
        final cols = await columns(tasks);
        final before = await rows(tasks);

        final created = await service.addRowWith(tasks.id, {
          cols[0].id: const TextValue('Recette'),
          cols[1].id: CategoryValue.single('Terminé'),
        });

        expect(created.id, before[2].id);
        expect(created[cols[0].id], const TextValue('Recette'));
        expect(created[cols[1].id], CategoryValue.single('Terminé'));
        expect(await rows(tasks), hasLength(3));
      },
    );

    test('sans ligne vide, une ligne est ajoutée à la fin', () async {
      final cols = await columns(tasks);
      await service.addRowWith(tasks.id, {cols[0].id: const TextValue('A')});

      final created = await service.addRowWith(tasks.id, {
        cols[0].id: const TextValue('B'),
      });

      expect(created.position, 3);
      expect(await rows(tasks), hasLength(4));
    });

    test('une valeur d\'un autre type que la colonne est refusée', () async {
      final cols = await columns(tasks);

      await expectLater(
        service.addRowWith(tasks.id, {cols[1].id: const NumberValue(3)}),
        throwsArgumentError,
      );
      expect((await rows(tasks))[2].isEmpty, isTrue);
    });

    test(
      'ajouter une catégorie la place à la fin, sans toucher aux cellules',
      () async {
        final status = (await columns(tasks))[1];

        expect(await service.addCategory(status, ' En recette '), isTrue);

        final after = (await columns(tasks))[1];
        expect(after.options, ['À faire', 'Terminé', 'En recette']);
        expect(categoriesOf(after, await rows(tasks)), after.options);
      },
    );

    test('une catégorie vide ou déjà définie est refusée', () async {
      final status = (await columns(tasks))[1];

      expect(await service.addCategory(status, '  '), isFalse);
      expect(await service.addCategory(status, 'Terminé'), isFalse);
      expect((await columns(tasks))[1].options, ['À faire', 'Terminé']);
    });
  });
}
