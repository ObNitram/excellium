import 'dart:io';

import 'package:excellium_app/app/excellium_app.dart';
import 'package:excellium_app/shared/providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_core/memory.dart';
import 'package:excellium_formula/excellium_formula.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Un classeur d'exemple sur le stockage en mémoire : une feuille « Tâches »
/// avec une colonne de chaque type et trois lignes, et une feuille « Équipe »
/// référencée par la colonne Responsable.
class Workbook {
  Workbook._(this.store, this.service);

  final InMemoryStore store;
  final WorkbookService service;

  late Sheet tasks;
  late Sheet team;

  static const titles = [
    'Tâche',
    'Budget',
    'Statut',
    'Étiquettes',
    'Validé',
    'Échéance',
    'Durée',
    'Avancement',
    'Responsable',
  ];

  static Future<Workbook> create() async {
    final store = InMemoryStore();
    final book = Workbook._(store, WorkbookService(store));
    await book._seed();
    return book;
  }

  Future<List<ColumnDef>> columns([Sheet? sheet]) =>
      store.columns.getColumns((sheet ?? tasks).id);

  Future<List<SheetRow>> rows([Sheet? sheet]) =>
      store.rows.getRows((sheet ?? tasks).id);

  Future<ColumnDef> column(String name, [Sheet? sheet]) async =>
      (await columns(sheet)).firstWhere((c) => c.name == name);

  Future<CellValue?> cell(int rowIndex, String columnName) async =>
      (await rows())[rowIndex][(await column(columnName)).id];

  Future<void> _seed() async {
    team = await service.createSheet(
      name: 'Équipe',
      columnCount: 2,
      rowCount: 3,
    );
    final teamColumns = await columns(team);
    await service.renameColumn(teamColumns[0], 'Nom');
    await service.renameColumn(teamColumns[1], 'Pôle');
    final people = await rows(team);
    const names = [
      ('Camille Martin', 'Design'),
      ('Hugo Petit', 'Développement'),
      ('Inès Moreau', 'Design'),
    ];
    for (final (index, (name, pole)) in names.indexed) {
      await store.rows.setCell(
        people[index].id,
        teamColumns[0].id,
        TextValue(name),
      );
      await store.rows.setCell(
        people[index].id,
        teamColumns[1].id,
        TextValue(pole),
      );
    }

    tasks = await service.createSheet(
      name: 'Tâches',
      columnCount: 9,
      rowCount: 3,
    );
    const types = [
      ColumnType.text,
      ColumnType.number,
      ColumnType.singleCategory,
      ColumnType.multiCategory,
      ColumnType.boolean,
      ColumnType.date,
      ColumnType.duration,
      ColumnType.percent,
      ColumnType.reference,
    ];
    for (final (index, type) in types.indexed) {
      var column = (await columns())[index];
      await service.renameColumn(column, titles[index]);
      column = (await columns())[index];
      await service.changeColumnType(column, type);
    }
    await service.configureReference(
      await column('Responsable'),
      ReferenceConfig(targetSheetId: team.id),
    );
    await service.reorderCategories(await column('Statut'), [
      'À faire',
      'En cours',
      'Terminé',
    ]);

    final cols = await columns();
    final taskRows = await rows();
    final data = <List<CellValue?>>[
      [
        const TextValue('Maquette'),
        const NumberValue(1200),
        CategoryValue.single('En cours'),
        CategoryValue(['Design', 'Urgent']),
        const BoolValue(true),
        DateValue(2026, 12, 4),
        const DurationValue(Duration(hours: 6, minutes: 30)),
        const NumberValue(60),
        ReferenceValue([people[0].id]),
      ],
      [
        const TextValue('Import CSV'),
        const NumberValue(850),
        CategoryValue.single('À faire'),
        CategoryValue(['Technique']),
        null,
        DateValue(2026, 12, 11),
        const DurationValue(Duration(hours: 4)),
        const NumberValue(0),
        ReferenceValue([people[1].id]),
      ],
      [
        const TextValue('Atelier client'),
        const NumberValue(600),
        CategoryValue.single('Terminé'),
        CategoryValue(['Client']),
        const BoolValue(true),
        DateValue(2026, 11, 27),
        const DurationValue(Duration(hours: 3)),
        const NumberValue(100),
        null,
      ],
    ];
    for (final (r, values) in data.indexed) {
      for (final (c, value) in values.indexed) {
        if (value != null) {
          await store.rows.setCell(taskRows[r].id, cols[c].id, value);
        }
      }
    }
  }
}

bool _fontsLoaded = false;

/// Charge la police Inter de l'application. Sans elle, les tests utilisent
/// une police dont chaque caractère est un carré, bien plus large : les
/// mesures (hauteur des barres, débordements) ne seraient pas celles de
/// l'application.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final loader = FontLoader('Inter');
  for (final file in Directory('assets/fonts/inter').listSync()) {
    if (file is File && file.path.endsWith('.otf')) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
  }
  await loader.load();
}

/// Lance l'application sur [store], dans une fenêtre de bureau.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  ExcelliumStore store, {
  Size size = const Size(1600, 1000),
}) async {
  await tester.runAsync(loadAppFonts);
  tester.view.physicalSize = size;
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
  return ProviderScope.containerOf(tester.element(find.byType(ExcelliumApp)));
}

/// Une cellule par sa référence. Son libellé d'accessibilité commence par
/// « Cellule B2 », suivi de son contenu quand elle n'est pas vide.
Finder cell(String reference) =>
    find.bySemanticsLabel(RegExp('^Cellule $reference(\\n|\$)'));

/// La référence affichée dans la barre d'édition (« B2 », « Budget »…).
Finder editReference(String text) => find.descendant(
  of: find.byKey(const Key('edit-reference')),
  matching: find.text(text),
);

/// Un texte dans le panneau flottant ouvert (menu de colonne, menu de vue…),
/// à ne pas confondre avec le même texte affiché dans la grille.
Finder inPanel(String text) => find.descendant(
  of: find.byKey(const Key('popover-panel')),
  matching: find.text(text),
);

/// Ouvre le menu d'une colonne par la flèche de son en-tête.
Future<void> openColumnMenu(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Options de la colonne $label'));
  await tester.pumpAndSettle();
}

/// Ferme le panneau ouvert en cliquant en dehors.
Future<void> closePanel(WidgetTester tester) async {
  await tester.tapAt(const Offset(1590, 990));
  await tester.pumpAndSettle();
}

/// Valide le texte du champ de la barre d'édition.
Future<void> enterInEditBar(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}
