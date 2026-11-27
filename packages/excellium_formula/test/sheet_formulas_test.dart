import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_formula/excellium_formula.dart';
import 'package:test/test.dart';

/// Le moteur branché sur le modèle de feuille, à travers `SheetFormulas`.
void main() {
  const sheetId = SheetId('s');
  final engine = ExcelliumFormulaEngine();

  var nextColumn = 0;
  ColumnDef col(String name, ColumnType type, {String formula = ''}) =>
      ColumnDef(
        id: ColumnId(name),
        sheetId: sheetId,
        position: nextColumn++,
        name: name,
        type: type,
        formula: formula,
      );

  SheetRow row(int position, Map<String, CellValue> cells) => SheetRow(
    id: RowId('r$position'),
    sheetId: sheetId,
    position: position,
    cells: {
      for (final entry in cells.entries) ColumnId(entry.key): entry.value,
    },
  );

  late List<ColumnDef> columns;
  late List<SheetRow> rows;

  SheetFormulas formulas([List<ColumnDef> extra = const []]) => SheetFormulas(
    engine: engine,
    columns: [...columns, ...extra],
    rows: rows,
  );

  setUp(() {
    nextColumn = 0;
    columns = [
      col('Tâche', ColumnType.text),
      col('Budget', ColumnType.number),
      col('Statut', ColumnType.singleCategory),
      col('Validé', ColumnType.boolean),
      col('Échéance', ColumnType.date),
      col('Durée', ColumnType.duration),
      col('Avancement', ColumnType.percent),
    ];
    rows = [
      row(0, {
        'Tâche': const TextValue('Maquette'),
        'Budget': const NumberValue(1200),
        'Statut': CategoryValue.single('En cours'),
        'Validé': const BoolValue(true),
        'Échéance': DateValue(2026, 12, 4),
        'Durée': const DurationValue(Duration(hours: 6, minutes: 30)),
        'Avancement': const NumberValue(60),
      }),
      row(1, {
        'Tâche': const TextValue('Import'),
        'Budget': const NumberValue(850),
        'Statut': CategoryValue.single('À faire'),
        'Échéance': DateValue(2026, 11, 20),
        'Durée': const DurationValue(Duration(hours: 4)),
        'Avancement': const NumberValue(0),
      }),
      row(2, {
        'Tâche': const TextValue('Atelier'),
        'Budget': const NumberValue(600),
        'Statut': CategoryValue.single('En cours'),
        'Validé': const BoolValue(true),
        'Avancement': const NumberValue(100),
      }),
      // Ligne entièrement vide : elle n'entre dans aucun calcul.
      row(3, const {}),
    ];
  });

  group('colonne Formule', () {
    test('une valeur par ligne renseignée', () {
      final reste = col(
        'Reste',
        ColumnType.formula,
        formula: 'Budget × (100 - Avancement) / 100',
      );
      final values = formulas([reste]).column(reste.id);

      expect(values.error, isNull);
      expect(values.values, {
        const RowId('r0'): 480,
        const RowId('r1'): 850,
        const RowId('r2'): 0,
      });
    });

    test('une fonction de colonne vaut pour chaque ligne', () {
      final part = col(
        'Part',
        ColumnType.formula,
        formula: 'Arrondi(Budget / Somme(Budget) * 100; 1)',
      );
      final values = formulas([part]).column(part.id);

      expect(values.values[const RowId('r0')], 45.3);
      expect(values.values.containsKey(const RowId('r3')), isFalse);
    });

    test('une formule peut citer une autre colonne Formule', () {
      final reste = col(
        'Reste',
        ColumnType.formula,
        formula: 'Budget * (100 - Avancement) / 100',
      );
      final double_ = col('Double', ColumnType.formula, formula: 'Reste * 2');
      final sheet = formulas([reste, double_]);

      expect(sheet.column(double_.id).values[const RowId('r0')], 960);
      expect(sheet.valueAt(double_, rows[1]), 1700);
    });

    test('une formule qui dépend d\'elle-même est une erreur', () {
      final a = col('A1', ColumnType.formula, formula: 'B1 + 1');
      final b = col('B1', ColumnType.formula, formula: 'A1 + 1');
      final self = col('Boucle', ColumnType.formula, formula: 'Boucle + 1');
      final sheet = formulas([a, b, self]);

      expect(sheet.column(self.id).error?.code, FormulaErrorCode.cyclic);
      expect(sheet.column(a.id).error, isNotNull);
      expect(sheet.column(b.id).error, isNotNull);
    });

    test('une formule en erreur casse celles qui la citent', () {
      final broken = col('Cassée', ColumnType.formula, formula: 'Budget +');
      final next = col('Suite', ColumnType.formula, formula: 'Cassée * 2');
      final sheet = formulas([broken, next]);

      expect(sheet.column(broken.id).error?.code, FormulaErrorCode.incomplete);
      expect(
        sheet.column(next.id).error,
        const FormulaError(FormulaErrorCode.brokenColumn, 'Cassée'),
      );
    });

    test('une formule vide ne donne ni valeur ni erreur', () {
      final empty = col('Vide', ColumnType.formula);
      final values = formulas([empty]).column(empty.id);

      expect(values.error, isNull);
      expect(values.values, isEmpty);
    });

    test('un résultat multiple est refusé', () {
      final multi = col(
        'Multi',
        ColumnType.formula,
        formula: 'Somme(Budget; Durée)',
      );

      expect(
        formulas([multi]).column(multi.id).error?.code,
        FormulaErrorCode.multipleNotCombinable,
      );
    });

    test('l\'unité suit le calcul', () {
      final total = col('Temps', ColumnType.formula, formula: 'Durée + Durée');

      expect(formulas([total]).column(total.id).unit, FormulaUnit.duration);
    });
  });

  group('types de colonne', () {
    test('durées en heures, dates comparables, booléens comptés', () {
      final sheet = formulas();

      expect((sheet.evaluate('Somme(Durée)') as FormulaScalar).value, 10.5);
      final min = sheet.evaluate('Min(Échéance)') as FormulaScalar;
      expect(
        formulaAsCell(min.value, min.unit)?.value,
        DateValue(2026, 11, 20),
      );
      expect((sheet.evaluate('Nombre(Validé)') as FormulaScalar).value, 2);
      expect((sheet.evaluate('Nombre(Statut)') as FormulaScalar).value, 3);
      expect((sheet.evaluate('Nombre(Tâche)') as FormulaScalar).value, 3);
    });

    test('une colonne sans nom se cite par sa lettre', () {
      final sheet = SheetFormulas(
        engine: engine,
        columns: [
          const ColumnDef(
            id: ColumnId('x'),
            sheetId: sheetId,
            position: 0,
            type: ColumnType.number,
          ),
        ],
        rows: [
          row(0, {'x': const NumberValue(4)}),
          row(1, {'x': const NumberValue(6)}),
        ],
      );

      expect((sheet.evaluate('Somme(A)') as FormulaScalar).value, 10);
    });
  });

  group('case de calcul', () {
    test('vide, texte ou calcul', () {
      final sheet = formulas();

      expect(sheet.calcCell('  '), isA<CalcBlank>());
      expect((sheet.calcCell('Total') as CalcText).text, 'Total');
      final result = sheet.calcCell('=Somme(Budget)') as CalcResult;
      expect((result.outcome as FormulaScalar).value, 2650);
    });

    test('« = » seul est un calcul incomplet', () {
      final result = formulas().calcCell('=') as CalcResult;

      expect(
        (result.outcome as FormulaFailure).error.code,
        FormulaErrorCode.incomplete,
      );
    });

    test('un calcul limité à certaines lignes ne voit qu\'elles', () {
      final reste = col(
        'Reste',
        ColumnType.formula,
        formula: 'Budget * (100 - Avancement) / 100',
      );
      final sheet = formulas([reste]);
      final enCours = [rows[0], rows[2]];

      final sum = sheet.calcCell('=Somme(Budget)', rows: enCours) as CalcResult;
      expect((sum.outcome as FormulaScalar).value, 1800);
      final rest = sheet.calcCell('=Somme(Reste)', rows: enCours) as CalcResult;
      expect((rest.outcome as FormulaScalar).value, 480);
      final count =
          sheet.calcCell('=Nombre(Tâche)', rows: const []) as CalcResult;
      expect((count.outcome as FormulaScalar).value, 0);
    });
  });

  group('affichage d\'un résultat', () {
    test('nombre arrondi à deux décimales, durée à la minute', () {
      expect(
        formulaAsCell(184.6153, FormulaUnit.number)?.value,
        const NumberValue(184.62),
      );
      expect(
        formulaAsCell(50.833, FormulaUnit.percent)?.type,
        ColumnType.percent,
      );
      expect(
        formulaAsCell(1.75, FormulaUnit.duration)?.value,
        const DurationValue(Duration(hours: 1, minutes: 45)),
      );
      expect(formulaAsCell(null, FormulaUnit.number), isNull);
      expect(formulaAsCell(double.nan, FormulaUnit.number), isNull);
    });
  });
}
