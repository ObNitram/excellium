import 'package:excellium_app/app/excellium_app.dart';
import 'package:excellium_app/shared/controls.dart';
import 'package:excellium_app/shared/providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_core/memory.dart';
import 'package:excellium_formula/excellium_formula.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' show editReference;

/// L'interface est testée sur le stockage en mémoire : aucun écran ne dépend
/// de SQLite.
void main() {
  late InMemoryStore store;
  late Sheet sheet;
  late List<ColumnDef> columns;
  late List<SheetRow> rows;

  Future<void> reload() async {
    columns = await store.columns.getColumns(sheet.id);
    rows = await store.rows.getRows(sheet.id);
  }

  setUp(() async {
    store = InMemoryStore();
    sheet = await WorkbookService(store)
        .createSheet(name: 'Tâches', columnCount: 3, rowCount: 4);
    await reload();
  });

  tearDown(() => store.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          formulaEngineProvider.overrideWithValue(ExcelliumFormulaEngine()),
        ],
        child: const ExcelliumApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Une cellule par sa référence. Son libellé d'accessibilité commence par
  /// « Cellule B2 », suivi de son contenu quand elle n'est pas vide.
  Finder cell(String reference) =>
      find.bySemanticsLabel(RegExp('^Cellule $reference(\\n|\$)'));

  testWidgets('affiche les onglets, les en-têtes et les numéros de ligne', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Tâches'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    // Le volet des cases de calcul numérote aussi ses lignes : on vise les
    // numéros de la table.
    expect(find.byTooltip('Options de la ligne 1'), findsOneWidget);
    expect(find.byTooltip('Options de la ligne 4'), findsOneWidget);
    expect(
      find.text('Sélectionnez une cellule pour la modifier.'),
      findsOneWidget,
    );
  });

  testWidgets('saisir un texte dans la barre d\'édition remplit la cellule', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(cell('B2'));
    await tester.pumpAndSettle();
    expect(editReference('B2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Import CSV');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await reload();
    expect(rows[1][columns[1].id], const TextValue('Import CSV'));
    expect(find.text('Import CSV'), findsWidgets);
  });

  testWidgets('Entrée valide puis passe à la ligne suivante, champ prêt', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(cell('A1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'un');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // La sélection est descendue en A2 et le champ a gardé le focus.
    expect(editReference('A2'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);
    expect(field.controller?.text, '');

    await tester.enterText(find.byType(TextField), 'deux');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await reload();
    expect(rows[0][columns[0].id], const TextValue('un'));
    expect(rows[1][columns[0].id], const TextValue('deux'));
  });

  testWidgets('sur la dernière ligne, Entrée valide sans changer de cellule', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(cell('A4'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fin');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(editReference('A4'), findsOneWidget);
    await reload();
    expect(rows[3][columns[0].id], const TextValue('fin'));
  });

  testWidgets('une saisie invalide affiche une erreur et ne change rien', (
    tester,
  ) async {
    await WorkbookService(store)
        .changeColumnType(columns[0], ColumnType.number);
    await pumpApp(tester);

    await tester.tap(cell('A1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'douze');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Saisissez un nombre, par exemple 12,5.'), findsOneWidget);
    // La sélection reste sur la cellule à corriger.
    expect(editReference('A1'), findsOneWidget);
    await reload();
    expect(rows[0].isEmpty, isTrue);
  });

  testWidgets('un nombre est affiché avec ses séparateurs', (tester) async {
    await WorkbookService(store)
        .changeColumnType(columns[0], ColumnType.number);
    await reload();
    await store.rows.setCell(
      rows[0].id,
      columns[0].id,
      const NumberValue(1234.5),
    );
    await pumpApp(tester);

    expect(find.text('1 234,5'), findsOneWidget);
  });

  testWidgets('changer le type depuis le menu de la colonne', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Options de la colonne A'));
    await tester.pumpAndSettle();
    // Le choix du type est une section repliée du menu.
    expect(find.text('Booléen'), findsNothing);
    await tester.tap(find.text('Type : Texte'));
    await tester.pumpAndSettle();
    // La liste des types est longue : on la fait défiler dans le panneau.
    await tester.ensureVisible(find.text('Booléen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Booléen'));
    await tester.pumpAndSettle();

    await reload();
    expect(columns[0].type, ColumnType.boolean);
    expect(find.byType(AppCheckbox), findsNWidgets(rows.length));
  });

  testWidgets('cocher une case enregistre un booléen', (tester) async {
    await WorkbookService(store)
        .changeColumnType(columns[0], ColumnType.boolean);
    await pumpApp(tester);

    await tester.tap(find.byType(AppCheckbox).first);
    await tester.pumpAndSettle();

    await reload();
    expect(rows[0][columns[0].id], const BoolValue(true));
  });

  testWidgets('renommer une colonne par double-clic sur son en-tête', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('B'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('Renommer la colonne B'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Budget');
    await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
    await tester.pumpAndSettle();

    await reload();
    expect(columns[1].name, 'Budget');
    // Le nom apparaît dans l'en-tête, et dans les barres puisque le premier
    // clic a sélectionné la colonne.
    expect(find.text('Budget'), findsWidgets);
  });

  testWidgets('ajouter une feuille l\'ouvre dans un nouvel onglet', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Ajouter une feuille'));
    await tester.pumpAndSettle();

    final sheets = await store.sheets.getSheets();
    expect(sheets.map((s) => s.name), ['Tâches', 'Feuille 2']);
    expect(find.text('Feuille 2'), findsOneWidget);
    // La nouvelle feuille a ses colonnes par défaut, donc une colonne F.
    expect(find.text('F'), findsOneWidget);
  });

  testWidgets('ajouter une colonne et une ligne', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Ajouter une colonne'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter une ligne'));
    await tester.pumpAndSettle();

    await reload();
    expect(columns, hasLength(4));
    expect(rows, hasLength(5));
    expect(find.text('D'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('un classeur vide reçoit une première feuille', (tester) async {
    await store.close();
    store = InMemoryStore();
    await pumpApp(tester);

    expect(find.text('Feuille 1'), findsOneWidget);
    expect(await store.sheets.getSheets(), hasLength(1));
  });
}
