import 'package:excellium_app/features/editing/edit_bar.dart';
import 'package:excellium_app/features/styling/style_bar.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late Workbook book;

  setUp(() async => book = await Workbook.create());
  tearDown(() => book.store.close());

  Future<void> select(WidgetTester tester, String reference) async {
    await pumpApp(tester, book.store);
    await tester.tap(find.text('Tâches'));
    await tester.pumpAndSettle();
    await tester.tap(cell(reference));
    await tester.pumpAndSettle();
  }

  testWidgets('nombre : les boutons − et + changent la valeur de 1', (
    tester,
  ) async {
    await select(tester, 'B1');

    await tester.tap(find.byTooltip('Augmenter de 1'));
    await tester.pumpAndSettle();
    expect(await book.cell(0, 'Budget'), const NumberValue(1201));

    await tester.tap(find.byTooltip('Diminuer de 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Diminuer de 1'));
    await tester.pumpAndSettle();
    expect(await book.cell(0, 'Budget'), const NumberValue(1199));
  });

  testWidgets('pourcentage : la saisie accepte le signe %', (tester) async {
    await select(tester, 'H2');

    await enterInEditBar(tester, '45 %');

    expect(await book.cell(1, 'Avancement'), const NumberValue(45));
  });

  testWidgets('date : la saisie JJ/MM/AAAA est enregistrée', (tester) async {
    await select(tester, 'F1');

    await enterInEditBar(tester, '24/12/2026');

    expect(await book.cell(0, 'Échéance'), DateValue(2026, 12, 24));
  });

  testWidgets('date : « Aujourd\'hui » met la date du jour', (tester) async {
    await select(tester, 'F1');

    await tester.tap(find.text('Aujourd\'hui'));
    await tester.pumpAndSettle();

    expect(
      await book.cell(0, 'Échéance'),
      DateValue.fromDateTime(DateTime.now()),
    );
  });

  testWidgets('durée : plusieurs écritures sont comprises', (tester) async {
    await select(tester, 'G1');

    await enterInEditBar(tester, '1h15');

    expect(
      await book.cell(0, 'Durée'),
      const DurationValue(Duration(hours: 1, minutes: 15)),
    );
  });

  testWidgets('catégorie unique : choisir une pastille remplace la valeur', (
    tester,
  ) async {
    await select(tester, 'C2');

    await tester.tap(find.byKey(const Key('category-Terminé')));
    await tester.pumpAndSettle();
    expect(await book.cell(1, 'Statut'), CategoryValue.single('Terminé'));

    // Rechoisir la même pastille vide la cellule.
    await tester.tap(find.byKey(const Key('category-Terminé')));
    await tester.pumpAndSettle();
    expect(await book.cell(1, 'Statut'), isNull);
  });

  testWidgets('catégorie multiple : chaque pastille s\'ajoute ou se retire', (
    tester,
  ) async {
    await select(tester, 'D2');

    await tester.tap(find.byKey(const Key('category-Urgent')));
    await tester.pumpAndSettle();
    expect(
      await book.cell(1, 'Étiquettes'),
      CategoryValue(['Technique', 'Urgent']),
    );

    await tester.tap(find.byKey(const Key('category-Technique')));
    await tester.pumpAndSettle();
    expect(await book.cell(1, 'Étiquettes'), CategoryValue(['Urgent']));
  });

  testWidgets(
    'catégorie : en créer une l\'ajoute à la colonne et à la cellule',
    (tester) async {
      await select(tester, 'C1');

      await tester.enterText(
        find.widgetWithText(TextField, 'Nouvelle catégorie'),
        'Bloqué',
      );
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      expect(await book.cell(0, 'Statut'), CategoryValue.single('Bloqué'));
      expect((await book.column('Statut')).options, contains('Bloqué'));
      expect(find.byKey(const Key('category-Bloqué')), findsOneWidget);
    },
  );

  testWidgets('booléen : Vrai ou Faux depuis la barre d\'édition', (
    tester,
  ) async {
    await select(tester, 'E2');

    await tester.tap(find.text('Vrai'));
    await tester.pumpAndSettle();
    expect(await book.cell(1, 'Validé'), const BoolValue(true));

    await tester.tap(find.text('Faux'));
    await tester.pumpAndSettle();
    expect(await book.cell(1, 'Validé'), const BoolValue(false));
  });

  testWidgets('la croix vide la cellule', (tester) async {
    await select(tester, 'A1');

    await tester.tap(find.byTooltip('Vider la cellule'));
    await tester.pumpAndSettle();

    expect(await book.cell(0, 'Tâche'), isNull);
  });

  testWidgets('la barre d\'édition garde sa hauteur d\'un type à l\'autre', (
    tester,
  ) async {
    await pumpApp(tester, book.store);
    await tester.tap(find.text('Tâches'));
    await tester.pumpAndSettle();
    // Sans sélection, les deux barres ont déjà leur hauteur définitive.
    final height = tester.getSize(find.byType(EditBar)).height;
    final styleHeight = tester.getSize(find.byType(StyleBar)).height;

    await tester.tap(cell('A1'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(EditBar)).height, height);
    expect(tester.getSize(find.byType(StyleBar)).height, styleHeight);

    for (final column in ['B', 'C', 'D', 'E', 'F', 'G', 'H', 'I']) {
      await tester.tap(cell('${column}1'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(EditBar)).height,
        height,
        reason: 'colonne $column',
      );
    }
  });

  group('référence', () {
    testWidgets('chercher puis choisir une ligne de la feuille liée', (
      tester,
    ) async {
      await select(tester, 'I3');
      expect(find.text('Aucune référence'), findsOneWidget);

      await tester.tap(find.text('Rechercher dans Équipe'));
      await tester.pumpAndSettle();
      expect(inPanel('Camille Martin'), findsOneWidget);
      expect(inPanel('Hugo Petit'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher une ligne'),
        'inès',
      );
      await tester.pumpAndSettle();
      expect(inPanel('Camille Martin'), findsNothing);

      await tester.tap(inPanel('Inès Moreau'));
      await tester.pumpAndSettle();

      final people = await book.rows(book.team);
      expect(await book.cell(2, 'Responsable'), ReferenceValue([people[2].id]));
      // En 1–n le panneau se referme et la sélection s'affiche.
      expect(find.byKey(const Key('popover-panel')), findsNothing);
      expect(find.text('Inès Moreau'), findsWidgets);
    });

    testWidgets('en 1–n, choisir une autre ligne remplace la référence', (
      tester,
    ) async {
      await select(tester, 'I1');

      await tester.tap(find.text('Rechercher dans Équipe'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Hugo Petit'));
      await tester.pumpAndSettle();

      final people = await book.rows(book.team);
      expect(await book.cell(0, 'Responsable'), ReferenceValue([people[1].id]));
    });

    testWidgets('en n–n, plusieurs lignes peuvent être choisies', (
      tester,
    ) async {
      final column = await book.column('Responsable');
      await book.service.configureReference(
        column,
        column.reference!.copyWith(cardinality: Cardinality.many),
      );
      await select(tester, 'I1');

      await tester.tap(find.text('Rechercher dans Équipe'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Hugo Petit'));
      await tester.pumpAndSettle();

      final people = await book.rows(book.team);
      expect(
        await book.cell(0, 'Responsable'),
        ReferenceValue([people[0].id, people[1].id]),
      );
      // Le panneau reste ouvert pour continuer à choisir.
      expect(find.byKey(const Key('popover-panel')), findsOneWidget);
    });

    testWidgets('la loupe règle les colonnes de recherche', (tester) async {
      await select(tester, 'I3');

      await tester.tap(find.byTooltip('Paramétrer la recherche'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Pôle'));
      await tester.pumpAndSettle();
      await closePanel(tester);

      final teamColumns = await book.columns(book.team);
      expect((await book.column('Responsable')).reference?.searchColumnIds, [
        teamColumns[0].id,
        teamColumns[1].id,
      ]);

      // La recherche trouve maintenant par le pôle.
      await tester.tap(find.text('Rechercher dans Équipe'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher une ligne'),
        'design',
      );
      await tester.pumpAndSettle();
      expect(inPanel('Camille Martin'), findsOneWidget);
      expect(inPanel('Inès Moreau'), findsOneWidget);
      expect(inPanel('Hugo Petit'), findsNothing);
    });

    testWidgets('la grille affiche le libellé de la ligne référencée', (
      tester,
    ) async {
      await pumpApp(tester, book.store);
      await tester.tap(find.text('Tâches'));
      await tester.pumpAndSettle();

      expect(find.text('Camille Martin'), findsOneWidget);

      // Renommer la personne dans « Équipe » met à jour la référence.
      final teamColumns = await book.columns(book.team);
      final people = await book.rows(book.team);
      await book.store.rows.setCell(
        people[0].id,
        teamColumns[0].id,
        const TextValue('Camille Durand'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camille Durand'), findsOneWidget);
      expect(find.text('Camille Martin'), findsNothing);
    });
  });
}
