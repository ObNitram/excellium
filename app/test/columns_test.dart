import 'package:excellium_app/shared/controls.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late Workbook book;

  setUp(() async => book = await Workbook.create());
  tearDown(() => book.store.close());

  Future<void> openTasks(WidgetTester tester) async {
    await pumpApp(tester, book.store);
    await tester.tap(find.text('Tâches'));
    await tester.pumpAndSettle();
  }

  group('sélection de colonne', () {
    testWidgets('un clic sur l\'en-tête sélectionne toute la colonne', (
      tester,
    ) async {
      await openTasks(tester);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(editReference('Budget'), findsOneWidget);
      expect(editReference('Budget'), findsOneWidget);
      expect(
        find.textContaining('Colonne entière sélectionnée'),
        findsOneWidget,
      );
    });

    testWidgets('cliquer une cellule revient à la sélection de cellule', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      await tester.tap(cell('B2'));
      await tester.pumpAndSettle();

      expect(editReference('B2'), findsOneWidget);
      expect(editReference('B2'), findsOneWidget);
    });
  });

  group('barre de style', () {
    testWidgets('gras sur une colonne sélectionnée : toute la colonne', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Gras'));
      await tester.pumpAndSettle();

      final column = await book.column('Budget');
      expect(column.style.bold, isTrue);
      for (final row in await book.rows()) {
        expect(resolveStyle(column, row).bold, isTrue);
        expect(row.styles, isEmpty);
      }
    });

    testWidgets('gras sur une cellule : cette cellule seulement', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(cell('B2'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Gras'));
      await tester.pumpAndSettle();

      final column = await book.column('Budget');
      final rows = await book.rows();
      expect(column.style.bold, isNull);
      expect(resolveStyle(column, rows[0]).bold, isFalse);
      expect(resolveStyle(column, rows[1]).bold, isTrue);
    });

    testWidgets('l\'alignement choisi est enregistré', (tester) async {
      await openTasks(tester);
      await tester.tap(find.text('Tâche'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Centrer'));
      await tester.pumpAndSettle();

      expect((await book.column('Tâche')).style.align, TextAlignment.center);
    });

    testWidgets('n\'affiche que les options qui ont un sens pour le type', (
      tester,
    ) async {
      await openTasks(tester);

      // Texte : style de texte, pas d'option d'affichage.
      await tester.tap(find.text('Tâche'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Gras'), findsOneWidget);
      expect(find.text('Interrupteur'), findsNothing);
      expect(find.text('Barre de progression'), findsNothing);

      // Catégorie : alignement seulement.
      await tester.tap(find.text('Statut'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Gras'), findsNothing);
      expect(find.byTooltip('Centrer'), findsOneWidget);

      // Booléen : choix de l'affichage, pas de style de texte.
      await tester.tap(find.text('Validé'));
      await tester.pumpAndSettle();
      expect(find.text('Interrupteur'), findsOneWidget);
      expect(find.byTooltip('Gras'), findsNothing);

      // Pourcentage : barre de progression et style de texte.
      await tester.tap(find.text('Avancement'));
      await tester.pumpAndSettle();
      expect(find.text('Barre de progression'), findsOneWidget);
      expect(find.byTooltip('Gras'), findsOneWidget);
    });

    testWidgets('un booléen peut s\'afficher en interrupteur ou en texte', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(find.text('Validé'));
      await tester.pumpAndSettle();
      expect(find.byType(AppCheckbox), findsNWidgets(3));

      await tester.tap(find.text('Interrupteur'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSwitch), findsNWidgets(3));
      expect(find.byType(AppCheckbox), findsNothing);

      await tester.tap(find.text('Vrai / Faux'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSwitch), findsNothing);
      expect(find.text('Vrai'), findsNWidgets(2));
      expect(find.text('Faux'), findsOneWidget);
      // En texte, le style de texte devient disponible.
      expect(find.byTooltip('Gras'), findsOneWidget);
    });

    testWidgets('en affichage texte, cliquer la cellule bascule le booléen', (
      tester,
    ) async {
      await book.service.styleColumn(
        await book.column('Validé'),
        const CellStyle(boolDisplay: BoolDisplay.text),
      );
      await openTasks(tester);

      await tester.tap(find.text('Faux'));
      await tester.pumpAndSettle();

      expect(await book.cell(1, 'Validé'), const BoolValue(true));
    });

    testWidgets('un pourcentage peut s\'afficher en barre de progression', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(find.text('Avancement'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('percent-bar')), findsNothing);

      await tester.tap(find.text('Barre de progression'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('percent-bar')), findsNWidgets(3));
      expect(
        (await book.column('Avancement')).style.percentDisplay,
        PercentDisplay.bar,
      );
    });
  });

  group('taille et ordre', () {
    testWidgets('glisser le bord droit d\'un en-tête règle la largeur', (
      tester,
    ) async {
      await openTasks(tester);
      final before = (await book.column('Budget')).width;

      await tester.drag(
        find.bySemanticsLabel('Régler la largeur de la colonne Budget'),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      final after = (await book.column('Budget')).width;
      expect(after, greaterThan(before + 30));
      expect(after, lessThanOrEqualTo(before + 60));
    });

    testWidgets('glisser le bord bas d\'un numéro de ligne règle la hauteur', (
      tester,
    ) async {
      await openTasks(tester);

      await tester.drag(
        find.bySemanticsLabel('Régler la hauteur de la ligne 2'),
        const Offset(0, 60),
      );
      await tester.pumpAndSettle();

      // Le geste ne compte qu'après un petit seuil de déplacement.
      final height = (await book.rows())[1].height;
      expect(height, isNotNull);
      expect(height, greaterThan(SheetRow.defaultHeight + 30));
      expect(height, lessThanOrEqualTo(SheetRow.defaultHeight + 60));
    });

    testWidgets('glisser un en-tête sur un autre déplace la colonne', (
      tester,
    ) async {
      await openTasks(tester);

      final from = tester.getCenter(find.text('Tâche'));
      final to = tester.getCenter(find.text('Statut'));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      final names = [for (final c in await book.columns()) c.name];
      // « Tâche » prend la place de « Statut ».
      expect(names.take(3), ['Budget', 'Statut', 'Tâche']);
      // Les données ont suivi la colonne.
      expect(await book.cell(0, 'Tâche'), const TextValue('Maquette'));
    });

    testWidgets('déposer une colonne sur sa voisine échange les deux', (
      tester,
    ) async {
      await openTasks(tester);

      final from = tester.getCenter(find.text('Budget'));
      final to = tester.getCenter(find.text('Statut'));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      final names = [for (final c in await book.columns()) c.name];
      expect(names.take(3), ['Tâche', 'Statut', 'Budget']);
    });

    testWidgets('glisser un onglet sur un autre le déplace', (tester) async {
      await pumpApp(tester, book.store);

      final from = tester.getCenter(find.text('Tâches'));
      final to = tester.getCenter(find.text('Équipe'));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      final sheets = await book.store.sheets.getSheets();
      expect(sheets.map((s) => s.name), ['Tâches', 'Équipe']);
    });
  });

  group('menu de colonne', () {
    testWidgets('près du bord droit, le menu reste dans la fenêtre', (
      tester,
    ) async {
      await pumpApp(tester, book.store, size: const Size(1200, 900));
      await tester.tap(find.text('Tâches'));
      await tester.pumpAndSettle();

      await openColumnMenu(tester, 'Responsable');

      final panel = tester.getRect(find.byKey(const Key('popover-panel')));
      expect(panel.right, lessThanOrEqualTo(1200));
      expect(panel.left, greaterThanOrEqualTo(0));
      // Il reste accroché à sa colonne.
      final anchor = tester.getRect(
        find.byTooltip('Options de la colonne Responsable'),
      );
      expect(panel.right, closeTo(anchor.right, 1));
    });

    testWidgets('Échap ferme le menu, même sans champ de saisie', (
      tester,
    ) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Budget');
      expect(find.byKey(const Key('popover-panel')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('popover-panel')), findsNothing);
    });

    testWidgets('masquer une colonne la retire de la grille', (tester) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Budget');
      await tester.tap(find.text('Masquer la colonne'));
      await tester.pumpAndSettle();

      expect(find.text('Budget'), findsNothing);
      expect(find.text('Colonnes : 1 masquée'), findsOneWidget);
      // La colonne et ses données existent toujours.
      expect(await book.cell(0, 'Budget'), const NumberValue(1200));
    });

    testWidgets('la relation d\'une référence se règle dans le menu', (
      tester,
    ) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Responsable');
      await tester.tap(find.text('Type : Référence'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('n – n'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('n – n'));
      await tester.pumpAndSettle();

      final column = await book.column('Responsable');
      expect(column.reference?.cardinality, Cardinality.many);
      expect(column.reference?.targetSheetId, book.team.id);
    });
  });
}
