import 'package:excellium_app/features/workbook/workbook_providers.dart';
import 'package:excellium_app/shared/controls.dart';
import 'package:excellium_app/shared/popover.dart';
import 'package:excellium_app/shared/providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// Barre de style complète (annuler, zoom, formats, police, couleurs,
/// bordures, fonctions) et menus de la barre de titre.
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

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> selectColumn(WidgetTester tester, String name) =>
      tap(tester, find.text(name).first);

  Future<void> selectCell(WidgetTester tester, String reference) =>
      tap(tester, cell(reference));

  bool enabled(WidgetTester tester, String tooltip) =>
      tester
          .widget<IconBtn>(
            find.ancestor(
              of: find.byTooltip(tooltip),
              matching: find.byType(IconBtn),
            ),
          )
          .onPressed !=
      null;

  /// Le texte affiché dans une cellule.
  Finder textIn(String reference, String text) =>
      find.descendant(of: cell(reference), matching: find.text(text));

  Future<CellStyle> columnStyle(String name) async =>
      (await book.column(name)).style;

  group('annuler et rétablir', () {
    testWidgets('les boutons annulent et rétablissent une saisie', (
      tester,
    ) async {
      await openTasks(tester);
      expect(enabled(tester, 'Annuler (Ctrl+Z)'), isFalse);
      expect(enabled(tester, 'Rétablir (Ctrl+Y)'), isFalse);

      await selectCell(tester, 'A1');
      await enterInEditBar(tester, 'Refonte');
      expect(await book.cell(0, 'Tâche'), const TextValue('Refonte'));
      expect(enabled(tester, 'Annuler (Ctrl+Z)'), isTrue);

      await tap(tester, find.byTooltip('Annuler (Ctrl+Z)'));
      expect(await book.cell(0, 'Tâche'), const TextValue('Maquette'));
      expect(enabled(tester, 'Rétablir (Ctrl+Y)'), isTrue);

      await tap(tester, find.byTooltip('Rétablir (Ctrl+Y)'));
      expect(await book.cell(0, 'Tâche'), const TextValue('Refonte'));
    });

    testWidgets('Ctrl+Z annule dans le classeur quand aucune saisie n\'est '
        'en cours, et la frappe sinon', (tester) async {
      await openTasks(tester);
      await tester.tap(cell('A1'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('Refonte');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // Le champ est passé à la ligne suivante, sans saisie en cours.
      expect(editReference('A2'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(await book.cell(0, 'Tâche'), const TextValue('Maquette'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(await book.cell(0, 'Tâche'), const TextValue('Refonte'));

      // Une saisie en cours : Ctrl+Z ne touche pas au classeur.
      tester.testTextInput.enterText('Brouillon');
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(await book.cell(0, 'Tâche'), const TextValue('Refonte'));
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('une colonne supprimée revient avec ses valeurs', (
      tester,
    ) async {
      await openTasks(tester);
      await openColumnMenu(tester, 'Budget');
      await tap(tester, inPanel('Supprimer la colonne'));
      expect(find.textContaining('Ctrl+Z annule la suppression'), findsOne);
      await tap(tester, find.widgetWithText(FilledButton, 'Supprimer'));
      expect(find.text('Budget'), findsNothing);

      await tap(tester, find.byTooltip('Annuler (Ctrl+Z)'));
      expect(find.text('Budget'), findsWidgets);
      expect(await book.cell(0, 'Budget'), const NumberValue(1200));
    });
  });

  group('zoom', () {
    testWidgets('le menu du zoom agrandit la feuille', (tester) async {
      await openTasks(tester);
      final normal = tester.getRect(cell('A1')).size;

      await tap(tester, find.byTooltip('Zoom'));
      await tap(tester, inPanel('150 %'));

      expect(container.read(zoomProvider), 1.5);
      expect(tester.getRect(cell('A1')).size, normal * 1.5);
      // Les cellules restent cliquables au bon endroit.
      await selectCell(tester, 'B2');
      expect(editReference('B2'), findsOneWidget);
    });

    testWidgets('Ctrl+- et Ctrl+0 règlent le zoom', (tester) async {
      await openTasks(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(zoomProvider), 0.9);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(zoomProvider), 1);
    });
  });

  group('police et taille', () {
    testWidgets('trois polices au choix, appliquées aux cellules', (
      tester,
    ) async {
      await openTasks(tester);
      await selectColumn(tester, 'Tâche');

      await tap(tester, find.byTooltip('Police'));
      expect(inPanel('Inter'), findsOneWidget);
      expect(inPanel('Liberation Serif'), findsOneWidget);
      expect(inPanel('JetBrains Mono'), findsOneWidget);
      await tap(tester, inPanel('JetBrains Mono'));

      expect((await columnStyle('Tâche')).font, CellFont.mono);
      final text = tester.widget<Text>(textIn('A1', 'Maquette'));
      expect(text.style?.fontFamily, 'JetBrains Mono');
    });

    testWidgets('la taille se choisit en points', (tester) async {
      await openTasks(tester);
      await selectCell(tester, 'A2');

      await tap(tester, find.byTooltip('Taille de police'));
      await tap(tester, inPanel('14'));

      final rows = await book.rows();
      final tache = await book.column('Tâche');
      expect(rows[1].styles[tache.id]?.fontSize, 14);
      final text = tester.widget<Text>(textIn('A2', 'Import CSV'));
      expect(text.style?.fontSize, closeTo(18.2, 0.01));
    });
  });

  group('couleurs et bordures', () {
    testWidgets('couleur du texte, remplissage, puis retour au défaut', (
      tester,
    ) async {
      await openTasks(tester);
      await selectColumn(tester, 'Tâche');

      await tap(tester, find.byTooltip('Couleur du texte'));
      await tap(tester, find.byTooltip('Rouge'));
      expect((await columnStyle('Tâche')).textColor, 0xFFB3261E);
      final text = tester.widget<Text>(textIn('A1', 'Maquette'));
      expect(text.style?.color, const Color(0xFFB3261E));

      await tap(tester, find.byTooltip('Couleur de remplissage'));
      await tap(tester, find.byTooltip('Jaune clair'));
      expect((await columnStyle('Tâche')).fillColor, 0xFFFFF8D6);

      await tap(tester, find.byTooltip('Couleur de remplissage'));
      await tap(tester, inPanel('Aucun remplissage'));
      expect((await columnStyle('Tâche')).fillColor, 0);
    });

    testWidgets('encadrer une cellule', (tester) async {
      await openTasks(tester);
      await selectCell(tester, 'A1');
      await tap(tester, find.byTooltip('Bordures'));
      await tap(tester, inPanel('Encadrer'));

      final rows = await book.rows();
      final tache = await book.column('Tâche');
      expect(rows[0].styles[tache.id]?.border, CellBorder.box);
    });

    testWidgets('retour à la ligne pour une colonne Texte', (tester) async {
      await openTasks(tester);
      await selectColumn(tester, 'Tâche');
      await tap(tester, find.byTooltip('Retour à la ligne automatique'));

      expect((await columnStyle('Tâche')).wrap, isTrue);
      final text = tester.widget<Text>(textIn('A1', 'Maquette'));
      expect(text.maxLines, isNull);
    });
  });

  group('format des nombres', () {
    testWidgets('décimales et symbole €', (tester) async {
      await openTasks(tester);
      await selectColumn(tester, 'Budget');

      await tap(tester, find.byTooltip('Ajouter des décimales'));
      await tap(tester, find.byTooltip('Ajouter des décimales'));
      expect((await columnStyle('Budget')).decimals, 2);
      expect(textIn('B1', '1 200,00'), findsOneWidget);

      await tap(tester, find.byTooltip('Format monétaire'));
      expect(textIn('B1', '1 200,00 €'), findsOneWidget);

      await tap(tester, find.byTooltip('Réduire les décimales'));
      expect(textIn('B1', '1 200,0 €'), findsOneWidget);
    });

    testWidgets('« 123 » propose les formats, % change le type', (
      tester,
    ) async {
      await openTasks(tester);
      await selectColumn(tester, 'Budget');

      await tap(tester, find.byTooltip('Autres formats de nombre'));
      await tap(tester, inPanel('Nombre'));
      expect(textIn('B2', '850,00'), findsOneWidget);

      await tap(tester, find.byTooltip('Autres formats de nombre'));
      await tap(tester, inPanel('Automatique'));
      expect(textIn('B2', '850'), findsOneWidget);

      await tap(
        tester,
        find.byTooltip('Format pourcentage (toute la colonne)'),
      );
      expect((await book.column('Budget')).type, ColumnType.percent);
    });

    testWidgets('Σ écrit le calcul sous la colonne', (tester) async {
      await openTasks(tester);
      await selectColumn(tester, 'Budget');

      await tap(tester, find.byTooltip('Fonctions'));
      await tap(tester, inPanel('Somme'));

      expect((await book.column('Budget')).calcCells, {0: '=Somme(Budget)'});
      expect(editReference('Calcul 1 · Budget'), findsOneWidget);
      expect(
        find.descendant(
          of: find.bySemanticsLabel(
            RegExp('^Case de calcul 1, colonne Budget'),
          ),
          matching: find.text('2 650'),
        ),
        findsOneWidget,
      );
    });
  });

  group('menus', () {
    Future<void> menu(WidgetTester tester, String name, String entry) async {
      await tap(tester, find.text(name));
      await tap(tester, inPanel(entry));
    }

    testWidgets('Fichier › Nouvelle feuille', (tester) async {
      await openTasks(tester);
      await menu(tester, 'Fichier', 'Nouvelle feuille');

      final sheets = await book.store.sheets.getSheets();
      expect(sheets, hasLength(3));
      expect(container.read(activeSheetProvider)?.id, sheets.last.id);
    });

    testWidgets('Édition › Annuler, Insertion › Ligne', (tester) async {
      await openTasks(tester);
      final before = (await book.rows()).length;

      await menu(tester, 'Insertion', 'Ligne');
      expect(await book.rows(), hasLength(before + 1));

      await menu(tester, 'Édition', 'Annuler');
      expect(await book.rows(), hasLength(before));
    });

    testWidgets('Affichage › Kanban, puis Grille', (tester) async {
      await openTasks(tester);
      await menu(tester, 'Affichage', 'Kanban');
      expect(find.text('Ajouter une étape'), findsOneWidget);

      await menu(tester, 'Affichage', 'Grille');
      expect(cell('A1'), findsOneWidget);
    });

    testWidgets('Données › Trier sur la colonne sélectionnée', (tester) async {
      await openTasks(tester);
      await selectColumn(tester, 'Budget');
      await menu(tester, 'Données', 'Trier par ordre croissant');

      expect(find.text('Trié par Budget, croissant'), findsOneWidget);
    });

    testWidgets('sans sélection, les entrées qui en ont besoin sont '
        'inactives', (tester) async {
      await openTasks(tester);
      await tap(tester, find.text('Format'));
      final gras = tester.widget<PanelItem>(
        find.ancestor(of: inPanel('Gras'), matching: find.byType(PanelItem)),
      );
      expect(gras.onTap, isNull);
    });
  });
}
