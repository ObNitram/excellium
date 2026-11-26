import 'package:excellium_app/features/views/view_providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// Renommer et supprimer une feuille, supprimer une colonne ou une ligne.
void main() {
  late Workbook book;
  late ProviderContainer container;

  setUp(() async => book = await Workbook.create());
  tearDown(() => book.store.close());

  Future<void> openTasks(WidgetTester tester) async {
    container = await pumpApp(tester, book.store);
    await tester.tap(find.text('Tâches'));
    await tester.pumpAndSettle();
  }

  Future<List<String>> sheetNames() async => [
    for (final sheet in await book.store.sheets.getSheets()) sheet.name,
  ];

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
  }

  group('feuille', () {
    testWidgets('double-cliquer un onglet le renomme', (tester) async {
      await openTasks(tester);

      await tester.tap(find.text('Tâches'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('Tâches'));
      await tester.pumpAndSettle();
      expect(find.text('Renommer la feuille'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Projets');
      await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
      await tester.pumpAndSettle();

      expect(await sheetNames(), ['Équipe', 'Projets']);
      expect(find.text('Projets'), findsOneWidget);
    });

    testWidgets('le menu de l\'onglet renomme la feuille', (tester) async {
      await openTasks(tester);

      await tester.tap(find.byTooltip('Options de la feuille Tâches'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Renommer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Suivi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(await sheetNames(), ['Équipe', 'Suivi']);
    });

    testWidgets('un nom vide ne change rien', (tester) async {
      await openTasks(tester);

      await tester.tap(find.byTooltip('Options de la feuille Tâches'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Renommer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '  ');
      await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
      await tester.pumpAndSettle();

      expect(await sheetNames(), ['Équipe', 'Tâches']);
    });

    testWidgets('le menu de l\'onglet s\'ouvre au-dessus de la barre', (
      tester,
    ) async {
      await openTasks(tester);

      await tester.tap(find.byTooltip('Options de la feuille Tâches'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byKey(const Key('popover-panel')));
      final tab = tester.getRect(
        find.byTooltip('Options de la feuille Tâches'),
      );
      expect(panel.bottom, lessThanOrEqualTo(tab.top));
      expect(panel.top, greaterThan(0));
    });

    testWidgets('supprimer une feuille demande confirmation', (tester) async {
      await openTasks(tester);

      await tester.tap(find.byTooltip('Options de la feuille Tâches'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la feuille'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer la feuille « Tâches » ?'), findsOneWidget);

      // Annuler ne supprime rien.
      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();
      expect(await sheetNames(), ['Équipe', 'Tâches']);

      await tester.tap(find.byTooltip('Options de la feuille Tâches'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la feuille'));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(await sheetNames(), ['Équipe']);
      // L'autre feuille est affichée à la place.
      expect(find.text('Camille Martin'), findsOneWidget);
      expect(find.text('Tâches'), findsNothing);
    });

    testWidgets('la confirmation annonce les références qui seront vidées', (
      tester,
    ) async {
      container = await pumpApp(tester, book.store);

      await tester.tap(find.byTooltip('Options de la feuille Équipe'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la feuille'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('La colonne « Responsable » (Tâches)'),
        findsOneWidget,
      );
      await confirm(tester);

      expect(await sheetNames(), ['Tâches']);
      final column = await book.column('Responsable');
      expect(column.reference?.targetSheetId, isNull);
      expect(await book.cell(0, 'Responsable'), isNull);
    });

    testWidgets('la dernière feuille ne se supprime pas', (tester) async {
      await book.service.deleteSheet(book.team.id);
      container = await pumpApp(tester, book.store);

      await tester.tap(find.byTooltip('Options de la feuille Tâches'));
      await tester.pumpAndSettle();
      expect(
        inPanel('Un classeur garde toujours au moins une feuille.'),
        findsOneWidget,
      );
      await tester.tap(inPanel('Supprimer la feuille'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer la feuille « Tâches » ?'), findsNothing);
      expect(await sheetNames(), ['Tâches']);
    });
  });

  group('colonne', () {
    Future<void> deleteFromMenu(WidgetTester tester, String column) async {
      await openColumnMenu(tester, column);
      await tester.ensureVisible(inPanel('Supprimer la colonne'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la colonne'));
      await tester.pumpAndSettle();
    }

    testWidgets('supprimer une colonne depuis son menu', (tester) async {
      await openTasks(tester);

      await deleteFromMenu(tester, 'Budget');
      expect(find.text('Supprimer la colonne « Budget » ?'), findsOneWidget);
      expect(
        find.textContaining(
          'Les 3 valeurs qu\'elle contient seront supprimées',
        ),
        findsOneWidget,
      );
      await confirm(tester);

      expect([
        for (final c in await book.columns()) c.name,
      ], isNot(contains('Budget')));
      expect(find.text('Budget'), findsNothing);
      // Les autres colonnes gardent leurs valeurs.
      expect(await book.cell(0, 'Tâche'), const TextValue('Maquette'));
    });

    testWidgets('annuler garde la colonne', (tester) async {
      await openTasks(tester);

      await deleteFromMenu(tester, 'Budget');
      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();

      expect(await book.cell(0, 'Budget'), const NumberValue(1200));
    });

    testWidgets('la colonne supprimée sort de la vue en cours', (tester) async {
      await openTasks(tester);
      final budget = await book.column('Budget');
      container.read(viewSpecProvider(book.tasks.id).notifier)
        ..toggleSort(budget.id, ascending: true)
        ..setFilter(budget.id, const NumberRange(min: 800));
      await tester.pumpAndSettle();
      expect(find.text('Budget ≥ 800'), findsOneWidget);

      await deleteFromMenu(tester, 'Budget');
      await confirm(tester);

      expect(container.read(viewSpecProvider(book.tasks.id)).isFull, isTrue);
      expect(find.text('Vue : complète'), findsOneWidget);
      // Toutes les lignes sont de nouveau affichées, dans leur ordre.
      expect(
        [
          for (final row in container.read(visibleRowsProvider(book.tasks.id)))
            row.position,
        ],
        [0, 1, 2],
      );
    });

    testWidgets('supprimer la colonne des étapes quitte proprement le kanban', (
      tester,
    ) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Statut');
      await tester.tap(find.text('Utiliser comme vue Kanban'));
      await tester.pumpAndSettle();
      // Retour à la grille pour atteindre le menu de la colonne.
      container
          .read(viewSpecProvider(book.tasks.id).notifier)
          .setLayout(const ViewLayout.grid());
      await tester.pumpAndSettle();

      await deleteFromMenu(tester, 'Statut');
      await confirm(tester);
      container
          .read(viewSpecProvider(book.tasks.id).notifier)
          .setLayout(const ViewLayout.kanban());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Aucune colonne de type « Catégorie unique »'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('la dernière colonne ne se supprime pas', (tester) async {
      final columns = await book.columns(book.team);
      await book.service.deleteColumn(columns[1]);
      container = await pumpApp(tester, book.store);

      await openColumnMenu(tester, 'Nom');
      await tester.ensureVisible(inPanel('Supprimer la colonne'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la colonne'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Supprimer la colonne « Nom »'), findsNothing);
      expect(await book.columns(book.team), hasLength(1));
    });
  });

  group('ligne', () {
    testWidgets('supprimer une ligne remplie demande confirmation', (
      tester,
    ) async {
      await openTasks(tester);

      await tester.tap(find.byTooltip('Options de la ligne 2'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la ligne 2'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer la ligne 2 ?'), findsOneWidget);
      await confirm(tester);

      final rows = await book.rows();
      expect(rows, hasLength(2));
      expect(await book.cell(0, 'Tâche'), const TextValue('Maquette'));
      expect(await book.cell(1, 'Tâche'), const TextValue('Atelier client'));
      expect(find.text('Import CSV'), findsNothing);
    });

    testWidgets('une ligne vide se supprime sans confirmation', (tester) async {
      await book.store.rows.addRow(book.tasks.id);
      await openTasks(tester);

      await tester.tap(find.byTooltip('Options de la ligne 4'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la ligne 4'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await book.rows(), hasLength(3));
    });

    testWidgets('la ligne supprimée sort des références qui la visaient', (
      tester,
    ) async {
      container = await pumpApp(tester, book.store);
      // Feuille « Équipe » : Camille Martin est responsable de « Maquette ».
      await tester.tap(find.byTooltip('Options de la ligne 1'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la ligne 1'));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(await book.cell(0, 'Responsable'), isNull);
      // Les autres références sont intactes.
      final people = await book.rows(book.team);
      expect(await book.cell(1, 'Responsable'), ReferenceValue([people[0].id]));
    });

    testWidgets('supprimer la ligne sélectionnée vide la barre d\'édition', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(cell('A2'));
      await tester.pumpAndSettle();
      expect(editReference('A2'), findsOneWidget);

      await tester.tap(find.byTooltip('Options de la ligne 2'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la ligne 2'));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(find.byKey(const Key('edit-reference')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
