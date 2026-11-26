import 'dart:ui' show Size;

import 'package:excellium_app/features/calendar/calendar_view.dart';
import 'package:excellium_app/features/views/view_providers.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';

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

  Future<void> chooseLayout(WidgetTester tester, String name) async {
    await tester.tap(find.textContaining('Affichage : '));
    await tester.pumpAndSettle();
    await tester.tap(inPanel(name));
    await tester.pumpAndSettle();
  }

  Future<void> dragTo(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('kanban', () {
    testWidgets('les catégories deviennent des étapes, les lignes des cartes', (
      tester,
    ) async {
      await openTasks(tester);
      await chooseLayout(tester, 'Kanban');

      expect(find.text('Affichage : Kanban'), findsOneWidget);
      expect(find.text('Étapes : Statut'), findsOneWidget);
      // Les étapes suivent l'ordre défini sur la colonne.
      final lanes = ['À faire', 'En cours', 'Terminé'];
      final xs = [
        for (final lane in lanes) tester.getTopLeft(find.text(lane)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(find.bySemanticsLabel(RegExp('^Carte Maquette')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Carte Import CSV')),
        findsOneWidget,
      );
      // Les autres valeurs de la ligne figurent sur la carte, avec leur nom.
      // Les milliers sont séparés par une espace insécable.
      expect(find.text('Budget : 1\u00a0200'), findsOneWidget);
      expect(find.text('Échéance : 04/12/2026'), findsOneWidget);
      // Une carte se limite à quatre champs : les colonnes suivantes n'y sont pas.
      expect(find.textContaining('Responsable : '), findsNothing);
    });

    testWidgets('glisser une carte vers une étape change la catégorie', (
      tester,
    ) async {
      await openTasks(tester);
      await chooseLayout(tester, 'Kanban');
      expect(await book.cell(1, 'Statut'), CategoryValue.single('À faire'));

      await dragTo(
        tester,
        tester.getCenter(find.text('Import CSV')),
        tester.getCenter(find.text('Terminé')) + const Offset(0, 60),
      );

      expect(await book.cell(1, 'Statut'), CategoryValue.single('Terminé'));
    });

    testWidgets('déplacer une étape change l\'ordre des catégories', (
      tester,
    ) async {
      await openTasks(tester);
      await chooseLayout(tester, 'Kanban');

      await tester.tap(
        find.byTooltip('Déplacer l\'étape À faire vers la droite'),
      );
      await tester.pumpAndSettle();

      expect((await book.column('Statut')).options, [
        'En cours',
        'À faire',
        'Terminé',
      ]);
    });

    testWidgets('une ligne sans catégorie va dans « Sans étape »', (
      tester,
    ) async {
      final status = await book.column('Statut');
      await book.store.rows.setCell((await book.rows())[2].id, status.id, null);
      await openTasks(tester);
      await chooseLayout(tester, 'Kanban');

      expect(find.text('Sans étape'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Carte Atelier client')),
        findsOneWidget,
      );
    });

    testWidgets('les filtres de la vue s\'appliquent aux cartes', (
      tester,
    ) async {
      await openTasks(tester);
      container
          .read(viewSpecProvider(book.tasks.id).notifier)
          .setFilter(
            (await book.column('Budget')).id,
            const NumberRange(min: 1000),
          );
      await chooseLayout(tester, 'Kanban');

      expect(find.bySemanticsLabel(RegExp('^Carte Maquette')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Carte Import CSV')), findsNothing);
      // L'étape reste affichée même si le filtre la vide.
      expect(find.text('À faire'), findsOneWidget);
    });

    testWidgets('« Utiliser comme vue Kanban » depuis le menu de la colonne', (
      tester,
    ) async {
      await openTasks(tester);

      await openColumnMenu(tester, 'Statut');
      await tester.tap(find.text('Utiliser comme vue Kanban'));
      await tester.pumpAndSettle();

      expect(find.text('Affichage : Kanban'), findsOneWidget);
      expect(find.text('Étapes : Statut'), findsOneWidget);
    });

    testWidgets('sans colonne catégorie, un message explique quoi faire', (
      tester,
    ) async {
      container = await pumpApp(tester, book.store);
      // La feuille « Équipe » n'a que des colonnes Texte.
      await chooseLayout(tester, 'Kanban');

      expect(
        find.textContaining('Aucune colonne de type « Catégorie unique »'),
        findsWidgets,
      );
    });
  });

  group('calendrier', () {
    Future<void> openDecember(WidgetTester tester) async {
      await openTasks(tester);
      await chooseLayout(tester, 'Calendrier');
      container
          .read(calendarMonthProvider(book.tasks.id).notifier)
          .show(DateTime(2026, 12));
      await tester.pumpAndSettle();
    }

    testWidgets('les lignes sont placées sur le jour de leur date', (
      tester,
    ) async {
      await openDecember(tester);

      expect(find.text('Affichage : Calendrier'), findsOneWidget);
      expect(find.text('Date : Échéance'), findsOneWidget);
      expect(find.text('Décembre 2026'), findsOneWidget);
      expect(find.text('Maquette'), findsOneWidget);
      expect(find.text('Import CSV'), findsOneWidget);
      // « Atelier client » est le 27 novembre, hors de la grille de décembre.
      expect(find.text('Atelier client'), findsNothing);

      // L'étiquette est dans la case du 4.
      final label = tester.getCenter(find.text('Maquette'));
      final day = tester.getRect(find.bySemanticsLabel('04/12/2026'));
      expect((label.dx - day.center.dx).abs(), lessThan(120));
      expect(label.dy, greaterThan(day.top));
    });

    testWidgets('naviguer d\'un mois à l\'autre', (tester) async {
      await openDecember(tester);

      await tester.tap(find.byTooltip('Mois précédent'));
      await tester.pumpAndSettle();

      expect(find.text('Novembre 2026'), findsOneWidget);
      expect(find.text('Atelier client'), findsOneWidget);
      expect(find.text('Import CSV'), findsNothing);
    });

    testWidgets('glisser une ligne vers un autre jour change sa date', (
      tester,
    ) async {
      await openDecember(tester);

      await dragTo(
        tester,
        tester.getCenter(find.text('Maquette')),
        tester.getCenter(find.bySemanticsLabel('17/12/2026')) +
            const Offset(20, 30),
      );

      expect(await book.cell(0, 'Échéance'), DateValue(2026, 12, 17));
    });

    testWidgets('une case trop basse annonce les lignes qui ne tiennent pas', (
      tester,
    ) async {
      // Trois lignes le même jour.
      final due = await book.column('Échéance');
      for (final row in await book.rows()) {
        await book.store.rows.setCell(row.id, due.id, DateValue(2026, 12, 4));
      }

      // Dans une grande fenêtre, les trois tiennent.
      await openDecember(tester);
      expect(find.text('Maquette'), findsOneWidget);
      expect(find.text('Atelier client'), findsOneWidget);
      expect(find.textContaining('autre'), findsNothing);

      // Dans une fenêtre peu haute, la case les annonce sans déborder.
      tester.view.physicalSize = const Size(1440, 700);
      await tester.pumpAndSettle();
      expect(find.text('+ 3 autres'), findsOneWidget);
      expect(find.text('Maquette'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('les lignes sans date sont comptées à part', (tester) async {
      final due = await book.column('Échéance');
      await book.store.rows.setCell((await book.rows())[1].id, due.id, null);
      await openDecember(tester);

      expect(find.text('1 ligne sans date'), findsOneWidget);
      expect(find.text('Import CSV'), findsNothing);
    });

    testWidgets(
      '« Utiliser comme vue Calendrier » depuis le menu de la colonne',
      (tester) async {
        await openTasks(tester);

        await openColumnMenu(tester, 'Échéance');
        await tester.tap(find.text('Utiliser comme vue Calendrier'));
        await tester.pumpAndSettle();

        expect(find.text('Affichage : Calendrier'), findsOneWidget);
        expect(find.text('Date : Échéance'), findsOneWidget);
      },
    );
  });
}
