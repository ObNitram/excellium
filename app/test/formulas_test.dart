import 'package:excellium_app/features/editing/edit_bar.dart';
import 'package:excellium_app/features/grid/grid_providers.dart';
import 'package:excellium_app/features/views/view_providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// Colonne Formule, cases de calcul sous la table, regroupement et opérations
/// de groupe.
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

  /// Ajoute une colonne Formule « Reste » en dixième position (lettre J).
  Future<ColumnDef> addFormula(String formula, {String name = 'Reste'}) async {
    final column = await book.store.columns.addColumn(
      book.tasks.id,
      name: name,
      type: ColumnType.formula,
    );
    await book.service.setFormula(column, formula);
    return book.column(name);
  }

  /// Saisit dans le champ de la barre d'édition, sans valider par Entrée.
  Future<void> typeInBar(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pumpAndSettle();
  }

  /// Clique à la souris, comme dans l'application de bureau : un clic hors
  /// d'un champ lui retire le focus.
  Future<void> click(WidgetTester tester, Finder target) async {
    await tester.tap(target, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  // Comme dans l'application de bureau, où un champ qui reçoit le focus
  // sélectionne tout son texte.
  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  /// Le champ qui reçoit ce qu'on tape, s'il y en a un.
  TextEditingController? focused(WidgetTester tester) {
    for (final field in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      if (field.focusNode.hasFocus) return field.controller;
    }
    return null;
  }

  String? focusedText(WidgetTester tester) => focused(tester)?.text;

  /// Vrai si le curseur est à la fin du champ, sans rien de sélectionné :
  /// taper complète le texte au lieu de le remplacer.
  bool caretAtEnd(WidgetTester tester) {
    final field = focused(tester)!;
    return field.selection ==
        TextSelection.collapsed(offset: field.text.length);
  }

  Finder calcCell(int row, String column) =>
      find.bySemanticsLabel(RegExp('^Case de calcul $row, colonne $column'));

  Finder groupHeader(String name) =>
      find.bySemanticsLabel(RegExp('^Groupe $name, '));

  Finder groupCalc(String group, String column) => find.bySemanticsLabel(
    RegExp('^Opération du groupe $group, colonne $column'),
  );

  Finder textIn(Finder parent, String text) =>
      find.descendant(of: parent, matching: find.text(text));

  ViewSpecNotifier view() =>
      container.read(viewSpecProvider(book.tasks.id).notifier);

  group('colonne Formule', () {
    testWidgets('ses cellules affichent le résultat de la formule', (
      tester,
    ) async {
      await addFormula('Budget × (100 - Avancement) / 100');
      await openTasks(tester);

      expect(textIn(cell('J1'), '480'), findsOneWidget);
      expect(textIn(cell('J2'), '850'), findsOneWidget);
      expect(textIn(cell('J3'), '0'), findsOneWidget);
    });

    testWidgets('le type se choisit dans le menu, la formule dans la barre '
        'd\'édition', (tester) async {
      await book.store.columns.addColumn(book.tasks.id, name: 'Double');
      await openTasks(tester);

      await openColumnMenu(tester, 'Double');
      await tester.tap(find.text('Type : Texte'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(inPanel('Formule'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Formule'));
      await tester.pumpAndSettle();

      // La colonne est sélectionnée et la barre d'édition attend la formule.
      expect((await book.column('Double')).type, ColumnType.formula);
      expect(editReference('Double'), findsOneWidget);
      expect(find.byKey(const Key('formula-editor')), findsOneWidget);

      // Le champ a déjà le focus : la formule se tape directement.
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.enterText('Budget * 2');
      await tester.pumpAndSettle();

      expect((await book.column('Double')).formula, 'Budget * 2');
      expect(textIn(cell('J1'), '2 400'), findsOneWidget);
      expect(textIn(cell('J2'), '1 700'), findsOneWidget);
    });

    testWidgets('la formule se saisit caractère par caractère sans perdre '
        'le focus', (tester) async {
      await addFormula('');
      await openTasks(tester);
      await tester.tap(cell('J1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      for (final text in ['B', 'Bu', 'Bud', 'Budg', 'Budge', 'Budget']) {
        tester.testTextInput.enterText(text);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.hasAnyClients, isTrue, reason: text);
      }

      expect((await book.column('Reste')).formula, 'Budget');
      expect(textIn(cell('J1'), '1 200'), findsOneWidget);
      // Les états intermédiaires étaient des erreurs : elles ont disparu.
      expect(find.text('#ERREUR'), findsNothing);
    });

    testWidgets('un clic sur une cellule calculée ouvre la formule', (
      tester,
    ) async {
      await addFormula('Budget * 2');
      await openTasks(tester);

      await click(tester, cell('J1'));
      expect(focusedText(tester), 'Budget * 2');
      // Chaque frappe est enregistrée pour toute la colonne : le curseur est
      // à la fin, une touche ne remplace pas la formule.
      expect(caretAtEnd(tester), isTrue);

      // Une autre ligne de la même colonne : c'est la même formule.
      await click(tester, cell('J3'));
      expect(focusedText(tester), 'Budget * 2');
      expect(caretAtEnd(tester), isTrue);
    }, variant: desktop);

    testWidgets('une formule incorrecte affiche #ERREUR et un message', (
      tester,
    ) async {
      await addFormula('Budget +');
      await openTasks(tester);
      await tester.tap(cell('J1'));
      await tester.pumpAndSettle();

      expect(find.text('#ERREUR'), findsNWidgets(3));
      expect(find.text('La formule est incomplète.'), findsOneWidget);

      await typeInBar(tester, 'Prix * 2');
      expect(find.text('Colonne inconnue : « Prix ».'), findsOneWidget);

      await typeInBar(tester, 'Budget * 2');
      expect(find.text('#ERREUR'), findsNothing);
      expect(
        find.text('Calculée pour chaque ligne de la colonne'),
        findsOneWidget,
      );
    });

    testWidgets('une cellule calculée montre la formule et ne se vide pas', (
      tester,
    ) async {
      await addFormula('Budget * 2');
      await openTasks(tester);

      await tester.tap(cell('J2'));
      await tester.pumpAndSettle();

      expect(editReference('J2'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Budget * 2'), findsOneWidget);
      expect(find.byTooltip('Vider la cellule'), findsNothing);
    });

    testWidgets('elle se trie et se filtre sur ses valeurs', (tester) async {
      final reste = await addFormula('Budget × (100 - Avancement) / 100');
      await openTasks(tester);
      List<int> shown() => [
        for (final row in container.read(visibleRowsProvider(book.tasks.id)))
          row.position + 1,
      ];

      view().toggleSort(reste.id, ascending: true);
      await tester.pumpAndSettle();
      // Reste : Atelier 0, Maquette 480, Import 850.
      expect(shown(), [3, 1, 2]);

      view().setFilter(reste.id, const NumberRange(min: 400));
      await tester.pumpAndSettle();
      expect(shown(), [1, 2]);
      expect(find.text('Reste ≥ 400'), findsOneWidget);
    });

    testWidgets('une formule peut citer une autre colonne Formule', (
      tester,
    ) async {
      await addFormula('Budget × (100 - Avancement) / 100');
      await addFormula('Arrondi(Reste / Somme(Reste) * 100)', name: 'Part');
      await openTasks(tester);

      // 480 / 1330 = 36 %, 850 / 1330 = 64 %.
      expect(textIn(cell('K1'), '36'), findsOneWidget);
      expect(textIn(cell('K2'), '64'), findsOneWidget);
    });
  });

  group('cases de calcul', () {
    testWidgets('un calcul se saisit dans la barre d\'édition, la case '
        'affiche le résultat', (tester) async {
      await openTasks(tester);

      await tester.tap(calcCell(1, 'Budget'));
      await tester.pumpAndSettle();
      expect(editReference('Calcul 1 · Budget'), findsOneWidget);
      expect(find.text('Case de calcul'), findsOneWidget);

      await typeInBar(tester, '=Somme(Budget)');

      expect(textIn(calcCell(1, 'Budget'), '2 650'), findsOneWidget);
      expect((await book.column('Budget')).calcCells, {0: '=Somme(Budget)'});
      // La barre d'édition garde la formule, pas le résultat.
      expect(find.widgetWithText(TextField, '=Somme(Budget)'), findsOneWidget);
    });

    testWidgets('sans « = », la case contient un simple texte', (tester) async {
      await openTasks(tester);

      await tester.tap(calcCell(1, 'Tâche'));
      await tester.pumpAndSettle();
      await typeInBar(tester, 'Total');

      expect(textIn(calcCell(1, 'Tâche'), 'Total'), findsOneWidget);
    });

    testWidgets('un calcul peut porter sur une autre colonne, et sur '
        'plusieurs', (tester) async {
      final budget = await book.column('Budget');
      await book.service.setCalcCell(budget, 1, '=Moyenne(Avancement)');
      await book.service.setCalcCell(
        await book.column('Budget'),
        2,
        '=Somme(Budget; Durée)',
      );
      await openTasks(tester);

      expect(textIn(calcCell(2, 'Budget'), '53,33 %'), findsOneWidget);
      expect(
        textIn(calcCell(3, 'Budget'), 'Budget 2 650 · Durée 13 h 30'),
        findsOneWidget,
      );
    });

    testWidgets('un calcul incorrect affiche #ERREUR et un message', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(calcCell(1, 'Budget'));
      await tester.pumpAndSettle();

      await typeInBar(tester, '=Somme(Prix)');

      expect(textIn(calcCell(1, 'Budget'), '#ERREUR'), findsOneWidget);
      expect(find.text('Colonne inconnue : « Prix ».'), findsOneWidget);
    });

    testWidgets('la barre d\'édition garde sa hauteur quand le calcul est en '
        'erreur', (tester) async {
      await openTasks(tester);
      await tester.tap(cell('A1'));
      await tester.pumpAndSettle();
      final height = tester.getSize(find.byType(EditBar)).height;

      await tester.tap(calcCell(1, 'Budget'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(EditBar)).height, height);

      // Pendant la saisie, presque chaque état est une erreur.
      await typeInBar(tester, '=Somme(');
      expect(find.text('La formule est incomplète.'), findsOneWidget);
      expect(tester.getSize(find.byType(EditBar)).height, height);
    });

    testWidgets('un clic sur une case ouvre la saisie, même déjà '
        'sélectionnée', (tester) async {
      await openTasks(tester);
      await click(tester, calcCell(1, 'Budget'));
      expect(focusedText(tester), '');

      tester.testTextInput.enterText('=Max(Budget)');
      await tester.pumpAndSettle();
      expect(textIn(calcCell(1, 'Budget'), '1 200'), findsOneWidget);

      // À la souris, le second clic retire le focus du champ puis le rend.
      await click(tester, calcCell(1, 'Budget'));
      expect(focusedText(tester), '=Max(Budget)');
      expect(caretAtEnd(tester), isTrue);

      await click(tester, calcCell(2, 'Durée'));
      expect(focusedText(tester), '');

      // Revenir sur une case remplie : on complète son calcul.
      await click(tester, calcCell(1, 'Budget'));
      expect(focusedText(tester), '=Max(Budget)');
      expect(caretAtEnd(tester), isTrue);
    }, variant: desktop);

    testWidgets('les boutons de fonction écrivent dans la case', (
      tester,
    ) async {
      await openTasks(tester);
      await tester.tap(calcCell(1, 'Budget'));
      await tester.pumpAndSettle();

      // À la souris, comme dans l'application de bureau : un clic hors d'un
      // champ lui retire le focus, sauf sur ses propres boutons.
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Moyenne'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '=Moyenne('), findsOneWidget);
      expect((await book.column('Budget')).calcCells, {0: '=Moyenne('});
      // La saisie continue au clavier, à la suite.
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.enterText('=Moyenne(Budget)');
      await tester.pumpAndSettle();
      expect(textIn(calcCell(1, 'Budget'), '883,33'), findsOneWidget);
    });

    testWidgets('les cases sont alignées sur les colonnes de la table', (
      tester,
    ) async {
      await openTasks(tester);

      for (final (letter, name) in [
        ('A', 'Tâche'),
        ('B', 'Budget'),
        ('F', 'Échéance'),
      ]) {
        final above = tester.getRect(cell('${letter}1'));
        final below = tester.getRect(calcCell(1, name));
        expect(below.left, above.left, reason: name);
        expect(below.width, above.width, reason: name);
      }
    });

    testWidgets('la table et les cases défilent ensemble à l\'horizontale', (
      tester,
    ) async {
      container = await pumpApp(tester, book.store, size: const Size(700, 900));
      await tester.tap(find.text('Tâches'));
      await tester.pumpAndSettle();
      final before = tester.getRect(cell('B1')).left;

      // On fait défiler la table…
      await tester.drag(cell('B2'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      final moved = tester.getRect(cell('B1')).left;
      expect(moved, lessThan(before - 100));
      // …les cases suivent,
      expect(tester.getRect(calcCell(1, 'Budget')).left, moved);

      // …et dans l'autre sens.
      await tester.drag(calcCell(1, 'Statut'), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(cell('B1')).left,
        tester.getRect(calcCell(1, 'Budget')).left,
      );
      expect(tester.getRect(cell('B1')).left, greaterThan(moved + 60));
    });

    testWidgets('les calculs portent sur toute la table, filtres ignorés', (
      tester,
    ) async {
      await book.service.setCalcCell(
        await book.column('Budget'),
        0,
        '=Somme(Budget)',
      );
      await openTasks(tester);

      view().setFilter(
        (await book.column('Budget')).id,
        const NumberRange(min: 1000),
      );
      await tester.pumpAndSettle();

      expect(textIn(calcCell(1, 'Budget'), '2 650'), findsOneWidget);
    });

    testWidgets('le volet se replie et se déplie', (tester) async {
      await openTasks(tester);
      expect(calcCell(1, 'Budget'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Replier les cases de calcul'));
      await tester.pumpAndSettle();
      expect(calcCell(1, 'Budget'), findsNothing);
      expect(find.text('Calculs'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Déplier les cases de calcul'));
      await tester.pumpAndSettle();
      expect(calcCell(1, 'Budget'), findsOneWidget);
    });

    testWidgets('sa hauteur se règle en tirant la barre ; tirée tout en bas, '
        'elle le replie', (tester) async {
      await openTasks(tester);
      final handle = find.bySemanticsLabel(
        'Régler la hauteur des cases de calcul',
      );
      final before = container.read(calcPaneProvider).height;

      await tester.drag(handle, const Offset(0, -80));
      await tester.pumpAndSettle();
      final taller = container.read(calcPaneProvider).height;
      expect(taller, greaterThan(before + 40));
      // Plus de lignes de cases sont visibles.
      expect(calcCell(4, 'Budget'), findsOneWidget);

      await tester.drag(handle, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(container.read(calcPaneProvider).hidden, isTrue);
      expect(calcCell(1, 'Budget'), findsNothing);
    });

    testWidgets('le volet a son propre défilement vertical', (tester) async {
      await openTasks(tester);
      expect(calcCell(12, 'Budget'), findsNothing);

      await tester.drag(calcCell(2, 'Budget'), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(calcCell(12, 'Budget'), findsOneWidget);
      // La table, elle, n'a pas bougé.
      expect(cell('A1'), findsOneWidget);
    });
  });

  group('regroupement', () {
    Future<void> groupBy(WidgetTester tester, String column) async {
      await tester.tap(find.text('Regrouper'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel(column));
      await tester.pumpAndSettle();
    }

    testWidgets('le menu Regrouper découpe la grille en groupes', (
      tester,
    ) async {
      await openTasks(tester);

      await groupBy(tester, 'Statut');

      expect(find.text('Regroupé par : Statut'), findsOneWidget);
      expect(
        container.read(viewSpecProvider(book.tasks.id)).groupBy,
        (await book.column('Statut')).id,
      );
      // Les groupes suivent l'ordre des catégories.
      final tops = [
        for (final name in ['À faire', 'En cours', 'Terminé'])
          tester.getTopLeft(groupHeader(name)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.bySemanticsLabel('Groupe En cours, 1 ligne'), findsOneWidget);
      // Chaque ligne est sous son groupe.
      expect(
        tester.getTopLeft(find.text('Import CSV')).dy,
        inExclusiveRange(tops[0], tops[1]),
      );
      expect(
        tester.getTopLeft(find.text('Maquette')).dy,
        inExclusiveRange(tops[1], tops[2]),
      );
      expect(find.bySemanticsLabel('Colonne de regroupement'), findsWidgets);
    });

    testWidgets('« Aucun regroupement » rend la grille complète', (
      tester,
    ) async {
      await openTasks(tester);
      await groupBy(tester, 'Statut');

      await tester.tap(find.text('Regroupé par : Statut'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Aucun regroupement'));
      await tester.pumpAndSettle();

      expect(groupHeader('En cours'), findsNothing);
      expect(find.text('Vue : complète'), findsOneWidget);
    });

    testWidgets('le menu d\'une colonne Catégorie ou Référence propose de '
        'regrouper', (tester) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Statut');
      await tester.tap(inPanel('Regrouper par cette colonne'));
      await tester.pumpAndSettle();
      expect(groupHeader('Terminé'), findsOneWidget);

      await openColumnMenu(tester, 'Statut');
      await tester.tap(inPanel('Ne plus regrouper'));
      await tester.pumpAndSettle();
      expect(groupHeader('Terminé'), findsNothing);

      // Une colonne Nombre ne se regroupe pas.
      await openColumnMenu(tester, 'Budget');
      expect(inPanel('Regrouper par cette colonne'), findsNothing);
    });

    testWidgets('un clic sur un groupe le replie', (tester) async {
      await openTasks(tester);
      await groupBy(tester, 'Statut');

      await tester.tap(groupHeader('En cours'));
      await tester.pumpAndSettle();

      expect(find.text('Maquette'), findsNothing);
      expect(find.text('Import CSV'), findsOneWidget);

      await tester.tap(groupHeader('En cours'));
      await tester.pumpAndSettle();
      expect(find.text('Maquette'), findsOneWidget);
    });

    testWidgets('une référence regroupe par ligne liée, dans l\'ordre de sa '
        'feuille', (tester) async {
      await openTasks(tester);

      await groupBy(tester, 'Responsable');

      expect(
        find.bySemanticsLabel('Groupe Camille Martin, 1 ligne'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Groupe Sans responsable, 1 ligne'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(groupHeader('Camille Martin')).dy,
        lessThan(tester.getTopLeft(groupHeader('Hugo Petit')).dy),
      );
    });

    testWidgets('une ligne à plusieurs étiquettes apparaît dans chaque '
        'groupe', (tester) async {
      await openTasks(tester);

      await groupBy(tester, 'Étiquettes');

      expect(groupHeader('Design'), findsOneWidget);
      expect(groupHeader('Urgent'), findsOneWidget);
      expect(find.text('Maquette'), findsNWidgets(2));
    });

    testWidgets('« Ajouter une ligne » crée une ligne dans le groupe', (
      tester,
    ) async {
      await openTasks(tester);
      await groupBy(tester, 'Statut');

      await tester.tap(
        find.bySemanticsLabel('Ajouter une ligne au groupe Terminé'),
      );
      await tester.pumpAndSettle();

      expect(await book.rows(), hasLength(4));
      expect(await book.cell(3, 'Statut'), CategoryValue.single('Terminé'));
      expect(find.bySemanticsLabel('Groupe Terminé, 2 lignes'), findsOneWidget);
      // La nouvelle ligne est prête à être remplie : on tape son nom.
      expect(editReference('A4'), findsOneWidget);
      tester.testTextInput.enterText('Bilan');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(await book.cell(3, 'Tâche'), const TextValue('Bilan'));
    });

    testWidgets('un filtre masque les groupes qu\'il vide', (tester) async {
      await openTasks(tester);
      await groupBy(tester, 'Statut');

      view().setFilter(
        (await book.column('Budget')).id,
        const NumberRange(min: 1000),
      );
      await tester.pumpAndSettle();

      expect(groupHeader('En cours'), findsOneWidget);
      expect(groupHeader('À faire'), findsNothing);
      expect(groupHeader('Terminé'), findsNothing);
    });

    testWidgets('le regroupement est enregistré avec la vue', (tester) async {
      await openTasks(tester);
      await groupBy(tester, 'Statut');

      await tester.tap(find.text('Enregistrer la vue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de la vue'),
        'Par statut',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Vue : Par statut'), findsOneWidget);

      view().reset();
      await tester.pumpAndSettle();
      expect(groupHeader('En cours'), findsNothing);

      await tester.tap(find.text('Vue : complète'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Par statut'));
      await tester.pumpAndSettle();
      expect(groupHeader('En cours'), findsOneWidget);
    });

    testWidgets('supprimer la colonne de regroupement rend la grille '
        'complète', (tester) async {
      await openTasks(tester);
      await groupBy(tester, 'Statut');

      await openColumnMenu(tester, 'Statut');
      await tester.ensureVisible(inPanel('Supprimer la colonne'));
      await tester.pumpAndSettle();
      await tester.tap(inPanel('Supprimer la colonne'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(container.read(viewSpecProvider(book.tasks.id)).isFull, isTrue);
      expect(find.text('Maquette'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('opération de groupe', () {
    Future<void> grouped(WidgetTester tester) async {
      await openTasks(tester);
      view().setGroupBy((await book.column('Statut')).id);
      await tester.pumpAndSettle();
    }

    testWidgets('une opération saisie sur un groupe vaut pour tous, chacun '
        'sur ses lignes', (tester) async {
      await book.store.rows.addRow(book.tasks.id);
      final rows = await book.rows();
      final columns = await book.columns();
      // Une seconde tâche « En cours », à 300.
      await book.store.rows.setCell(
        rows[3].id,
        columns[0].id,
        const TextValue('Revue'),
      );
      await book.store.rows.setCell(
        rows[3].id,
        columns[1].id,
        const NumberValue(300),
      );
      await book.store.rows.setCell(
        rows[3].id,
        columns[2].id,
        CategoryValue.single('En cours'),
      );
      await grouped(tester);

      await tester.tap(groupCalc('En cours', 'Budget'));
      await tester.pumpAndSettle();
      expect(editReference('Calcul de groupe · Budget'), findsOneWidget);
      expect(find.text('Opération de groupe'), findsOneWidget);

      await typeInBar(tester, '=Somme(Budget)');

      expect((await book.column('Budget')).groupCalc, '=Somme(Budget)');
      expect(textIn(groupCalc('En cours', 'Budget'), '1 500'), findsOneWidget);
      expect(textIn(groupCalc('À faire', 'Budget'), '850'), findsOneWidget);
      expect(textIn(groupCalc('Terminé', 'Budget'), '600'), findsOneWidget);
    });

    testWidgets('un clic sur l\'opération d\'un autre groupe garde la saisie', (
      tester,
    ) async {
      await grouped(tester);
      await click(tester, groupCalc('En cours', 'Budget'));
      tester.testTextInput.enterText('=Somme(Budget)');
      await tester.pumpAndSettle();

      // Même colonne, autre groupe : le contenu est le même, et le champ
      // reprend la saisie.
      await click(tester, groupCalc('Terminé', 'Budget'));
      expect(focusedText(tester), '=Somme(Budget)');
      expect(caretAtEnd(tester), isTrue);
    }, variant: desktop);

    testWidgets('moyenne d\'une colonne par groupe', (tester) async {
      await book.service.setGroupCalc(
        await book.column('Avancement'),
        '=Moyenne(Avancement)',
      );
      await grouped(tester);

      expect(
        textIn(groupCalc('En cours', 'Avancement'), '60 %'),
        findsOneWidget,
      );
      expect(
        textIn(groupCalc('Terminé', 'Avancement'), '100 %'),
        findsOneWidget,
      );
    });

    testWidgets('le résultat reste visible quand le groupe est replié', (
      tester,
    ) async {
      await book.service.setGroupCalc(
        await book.column('Budget'),
        '=Somme(Budget)',
      );
      await grouped(tester);

      await tester.tap(groupHeader('En cours'));
      await tester.pumpAndSettle();

      expect(find.text('Maquette'), findsNothing);
      expect(textIn(groupCalc('En cours', 'Budget'), '1 200'), findsOneWidget);
    });

    testWidgets('avec un filtre, l\'opération ne compte que les lignes '
        'affichées', (tester) async {
      await book.store.rows.addRow(book.tasks.id);
      final rows = await book.rows();
      final columns = await book.columns();
      await book.store.rows.setCell(
        rows[3].id,
        columns[1].id,
        const NumberValue(300),
      );
      await book.store.rows.setCell(
        rows[3].id,
        columns[2].id,
        CategoryValue.single('En cours'),
      );
      await book.service.setGroupCalc(
        await book.column('Budget'),
        '=Somme(Budget)',
      );
      await grouped(tester);
      expect(textIn(groupCalc('En cours', 'Budget'), '1 500'), findsOneWidget);

      view().setFilter(
        (await book.column('Budget')).id,
        const NumberRange(min: 1000),
      );
      await tester.pumpAndSettle();

      expect(textIn(groupCalc('En cours', 'Budget'), '1 200'), findsOneWidget);
    });

    testWidgets('les cases d\'opération sont alignées sur les colonnes', (
      tester,
    ) async {
      await grouped(tester);

      final above = tester.getRect(cell('B1'));
      final op = tester.getRect(groupCalc('En cours', 'Budget'));
      expect(op.left, above.left);
      expect(op.width, above.width);
    });
  });
}
