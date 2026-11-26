import 'package:excellium_app/app/excellium_app.dart';
import 'package:excellium_app/shared/providers.dart';
import 'package:excellium_formula/excellium_formula.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// Les traits de la grille font un seul pixel de l'écran, d'une seule
/// couleur, même sur un écran réglé à 125 % ou 150 % où 1 point fait 1,25
/// ou 1,5 pixel.
void main() {
  late Workbook book;

  setUp(() async => book = await Workbook.create());
  tearDown(() => book.store.close());

  /// Rend l'application à [ratio] pixels par point et renvoie, pour chaque
  /// sonde, les suites de pixels identiques (couleur, longueur).
  Future<Map<String, List<(String, int)>>> render(
    WidgetTester tester,
    double ratio, {
    double zoom = 1,
  }) async {
    await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = Size(1600 * ratio, 1000 * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(book.store),
            formulaEngineProvider.overrideWithValue(ExcelliumFormulaEngine()),
          ],
          child: const ExcelliumApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tâches'));
    await tester.pumpAndSettle();
    if (zoom != 1) {
      ProviderScope.containerOf(tester.element(find.byType(ExcelliumApp)))
          .read(zoomProvider.notifier)
          .set(zoom);
      await tester.pumpAndSettle();
    }

    // Positions à l'écran, zoom compris.
    final a1 = tester.getRect(cell('A1'));
    final b3 = tester.getRect(cell('B3'));
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = (await image.toByteData())!;
      String at(int x, int y) {
        final i = (y * image.width + x) * 4;
        return [
          for (var c = 0; c < 3; c++)
            data.getUint8(i + c).toRadixString(16).padLeft(2, '0'),
        ].join();
      }

      List<(String, int)> runs(List<String> pixels) {
        final result = <(String, int)>[];
        for (var i = 0; i < pixels.length;) {
          var j = i;
          while (j < pixels.length && pixels[j] == pixels[i]) {
            j++;
          }
          result.add((pixels[i], j - i));
          i = j;
        }
        return result;
      }

      int px(double points) => (points * ratio).round();
      // Verticalement, dans la marge gauche de la colonne A, de l'en-tête
      // jusqu'à la ligne 3 : on croise les traits entre les lignes.
      final x = px(a1.left + 3);
      final down = [
        for (var y = px(a1.top - 20); y < px(b3.bottom + 2); y++) at(x, y),
      ];
      // Horizontalement, en haut de la ligne 3 (au-dessus du texte), du
      // numéro de ligne à la fin de la colonne B : on croise les traits
      // entre les colonnes.
      final y = px(b3.top + 3);
      final across = [
        for (var x = px(a1.left - 20); x < px(b3.right + 2); x++) at(x, y),
      ];
      return {'down': runs(down), 'across': runs(across)};
    }))!;
  }

  for (final (ratio, zoom) in [
    (1.0, 1.0),
    (1.25, 1.0),
    (1.5, 1.0),
    (1.0, 0.9),
    (1.0, 1.25),
    (1.25, 1.5),
  ]) {
    testWidgets('écran à ${(ratio * 100).round()} %, zoom à '
        '${(zoom * 100).round()} % : un trait fait un pixel', (tester) async {
      final probes = await render(tester, ratio, zoom: zoom);
      for (final MapEntry(key: name, value: runs) in probes.entries) {
        // Que des couleurs franches : fond, en-tête, traits.
        expect(
          runs.map((run) => run.$1).toSet(),
          everyElement(isIn({'ffffff', 'f4f5f7', 'e3e6ea', 'd5d9df'})),
          reason: '$name : $runs',
        );
        // Chaque trait fait exactement un pixel.
        for (final (color, length) in runs) {
          if (color == 'e3e6ea' || color == 'd5d9df') {
            expect(length, 1, reason: '$name : $runs');
          }
        }
        expect(
          runs.where((run) => run.$1 == 'e3e6ea'),
          isNotEmpty,
          reason: '$name : $runs',
        );
      }
    });
  }
}
