import 'package:excellium_app/features/views/view_bar.dart';
import 'package:excellium_app/features/views/view_providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

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

  /// Rangs (à partir de 1) des lignes affichées, dans l'ordre d'affichage.
  List<int> shownRows() => [
    for (final row in container.read(visibleRowsProvider(book.tasks.id)))
      row.position + 1,
  ];

  group('tri', () {
    testWidgets('trier depuis le menu de la colonne réordonne les lignes', (
      tester,
    ) async {
      await openTasks(tester);
      expect(shownRows(), [1, 2, 3]);

      await openColumnMenu(tester, 'Budget');
      await tester.tap(find.text('Croissant'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [3, 2, 1]);
      expect(find.text('Trié par Budget, croissant'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Colonne triée')), findsOneWidget);
      // Le tri ne change pas les données : les rangs enregistrés restent.
      expect([for (final r in await book.rows()) r.position], [0, 1, 2]);
    });

    testWidgets('redemander le même tri le retire', (tester) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Budget');
      await tester.tap(find.text('Décroissant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Décroissant'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [1, 2, 3]);
      expect(find.textContaining('Trié par'), findsNothing);
    });
  });

  group('filtre', () {
    testWidgets('filtrer une catégorie masque les autres lignes', (
      tester,
    ) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Statut');
      await tester.tap(inPanel('En cours'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [1]);
      expect(find.text('Statut est En cours'), findsOneWidget);
      expect(find.text('1 ligne affichée sur 3'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Colonne filtrée')), findsOneWidget);
      expect(find.text('Import CSV'), findsNothing);
    });

    testWidgets('filtrer un texte', (tester) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Tâche');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contient…'),
        'client',
      );
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [3]);
      expect(find.text('Tâche contient « client »'), findsOneWidget);
    });

    testWidgets('filtrer un nombre par un minimum', (tester) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Budget');
      await tester.enterText(
        find.byKey(const Key('filter-field-Minimum')),
        '800',
      );
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [1, 2]);
      expect(find.text('Budget ≥ 800'), findsOneWidget);
    });

    testWidgets('le champ de filtre garde le focus pendant la saisie', (
      tester,
    ) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Budget');
      await tester.tap(find.byKey(const Key('filter-field-Minimum')));
      await tester.pumpAndSettle();

      // Saisie caractère par caractère, comme au clavier : le filtre devient
      // actif dès le premier, et le champ doit rester en cours de saisie.
      for (final text in ['8', '80', '800']) {
        tester.testTextInput.enterText(text);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.hasAnyClients, isTrue, reason: text);
      }
      await closePanel(tester);

      expect(find.text('Budget ≥ 800'), findsOneWidget);
      expect(shownRows(), [1, 2]);
    });

    testWidgets('« Effacer » retire le filtre et vide les champs', (
      tester,
    ) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Budget');
      await tester.enterText(
        find.byKey(const Key('filter-field-Minimum')),
        '800',
      );
      await tester.pumpAndSettle();

      await tester.tap(inPanel('Effacer'));
      await tester.pumpAndSettle();

      expect(shownRows(), [1, 2, 3]);
      expect(inPanel('800'), findsNothing);
    });

    testWidgets('filtrer un booléen', (tester) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Validé');
      await tester.tap(inPanel('Faux'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [2]);
      expect(find.text('Validé est Faux'), findsOneWidget);
    });

    testWidgets('filtrer une référence par la ligne visée', (tester) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Responsable');
      await tester.tap(inPanel('Hugo Petit'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(shownRows(), [2]);
      expect(find.text('Responsable est Hugo Petit'), findsOneWidget);
    });

    testWidgets('retirer un critère depuis la barre de vue', (tester) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Statut');
      await tester.tap(inPanel('En cours'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      await tester.tap(find.byTooltip('Retirer : Statut est En cours'));
      await tester.pumpAndSettle();

      expect(shownRows(), [1, 2, 3]);
      expect(find.text('Statut est En cours'), findsNothing);
    });

    testWidgets('tri et filtre se cumulent', (tester) async {
      await openTasks(tester);
      container
          .read(viewSpecProvider(book.tasks.id).notifier)
          .setFilter(
            (await book.column('Budget')).id,
            const NumberRange(min: 700),
          );
      container
          .read(viewSpecProvider(book.tasks.id).notifier)
          .toggleSort((await book.column('Budget')).id, ascending: true);
      await tester.pumpAndSettle();

      expect(shownRows(), [2, 1]);
    });
  });

  testWidgets('la barre de vue garde sa hauteur quand un critère apparaît', (
    tester,
  ) async {
    await openTasks(tester);
    final empty = tester.getSize(find.byType(ViewBar)).height;

    container
        .read(viewSpecProvider(book.tasks.id).notifier)
        .toggleSort((await book.column('Budget')).id, ascending: false);
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer la vue'), findsOneWidget);
    expect(tester.getSize(find.byType(ViewBar)).height, empty);

    await tester.tap(find.text('Enregistrer la vue'));
    await tester.pumpAndSettle();
    expect(find.text('Annuler'), findsOneWidget);
    expect(tester.getSize(find.byType(ViewBar)).height, empty);
  });

  group('colonnes masquées', () {
    testWidgets('décocher une colonne dans le menu Colonnes la masque', (
      tester,
    ) async {
      await openTasks(tester);

      await tester.tap(find.text('Colonnes'));
      await tester.pumpAndSettle();
      // La ligne affiche le nom de la colonne puis son type, tous deux « Durée ».
      await tester.tap(inPanel('Durée').first);
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(find.text('Durée'), findsNothing);
      expect(find.text('Colonnes : 1 masquée'), findsOneWidget);

      await tester.tap(find.text('Colonnes : 1 masquée'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tout afficher'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      expect(find.text('Durée'), findsOneWidget);
    });
  });

  group('vues enregistrées', () {
    testWidgets('enregistrer la vue puis la retrouver', (tester) async {
      await openTasks(tester);
      expect(find.text('Vue : complète'), findsOneWidget);
      expect(find.text('Enregistrer la vue'), findsNothing);

      await openColumnMenu(tester, 'Statut');
      await tester.tap(inPanel('En cours'));
      await tester.pumpAndSettle();
      await closePanel(tester);
      expect(find.text('Vue : non enregistrée'), findsOneWidget);

      await tester.tap(find.text('Enregistrer la vue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de la vue'),
        'Suivi',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
      await tester.pumpAndSettle();

      final saved = await book.store.views.getViews(book.tasks.id);
      expect(saved.single.name, 'Suivi');
      expect(find.text('Vue : Suivi'), findsOneWidget);
      expect(find.text('Enregistrer la vue'), findsNothing);

      // On efface les critères, puis on réapplique la vue enregistrée.
      await tester.tap(find.text('Tout effacer'));
      await tester.pumpAndSettle();
      expect(find.text('Vue : complète'), findsOneWidget);
      expect(shownRows(), [1, 2, 3]);

      await tester.tap(find.text('Vue : complète'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Suivi'));
      await tester.pumpAndSettle();

      expect(find.text('Vue : Suivi'), findsOneWidget);
      expect(shownRows(), [1]);
    });

    testWidgets(
      'une vue enregistre aussi les colonnes masquées et l\'affichage',
      (tester) async {
        final status = await book.column('Statut');
        final duration = await book.column('Durée');
        await book.service.saveView(
          book.tasks.id,
          ViewSpec(
            layout: ViewLayout.kanban(status.id),
            hiddenColumnIds: [duration.id],
          ),
          name: 'Par étape',
        );
        await openTasks(tester);

        await tester.tap(find.text('Vue : complète'));
        await tester.pumpAndSettle();
        await tester.tap(inPanel('Par étape'));
        await tester.pumpAndSettle();

        expect(find.text('Vue : Par étape'), findsOneWidget);
        expect(find.text('Affichage : Kanban'), findsOneWidget);
        expect(find.text('Colonnes : 1 masquée'), findsOneWidget);
      },
    );

    testWidgets('supprimer une vue enregistrée', (tester) async {
      await book.service.saveView(
        book.tasks.id,
        ViewSpec(layout: const ViewLayout.calendar()),
        name: 'Échéances',
      );
      await openTasks(tester);

      await tester.tap(find.text('Vue : complète'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Supprimer la vue Échéances'));
      await tester.pumpAndSettle();

      expect(await book.store.views.getViews(book.tasks.id), isEmpty);
      expect(
        find.text('Aucune vue enregistrée pour cette feuille.'),
        findsOneWidget,
      );
    });

    testWidgets('chaque feuille a sa propre vue en cours', (tester) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Budget');
      await tester.tap(find.text('Croissant'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      await tester.tap(find.text('Équipe'));
      await tester.pumpAndSettle();
      expect(find.text('Vue : complète'), findsOneWidget);

      await tester.tap(find.text('Tâches'));
      await tester.pumpAndSettle();
      expect(find.text('Trié par Budget, croissant'), findsOneWidget);
    });
  });
}
