import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_formula/excellium_formula.dart';
import 'package:test/test.dart';

/// Colonnes de test, indépendantes du modèle de feuille.
final class _Scope implements FormulaScope {
  static double _day(int y, int m, int d) =>
      DateTime.utc(y, m, d).millisecondsSinceEpoch /
      Duration.millisecondsPerDay;

  static final Map<String, FormulaOperand> _columns = {
    'budget': const FormulaSeries([
      1200,
      850,
      400,
      600,
      300,
      950,
    ], name: 'Budget'),
    'b': const FormulaSeries([1200, 850, 400, 600, 300, 950], name: 'Budget'),
    'duree': const FormulaSeries(
      [6.5, 4, 2.25, 3, 1.75, 5],
      unit: FormulaUnit.duration,
      name: 'Durée',
    ),
    'avancement': const FormulaSeries(
      [60, 0, 35, 100, 10, 100],
      unit: FormulaUnit.percent,
      name: 'Avancement',
    ),
    'echeance': FormulaSeries(
      [_day(2026, 12, 4), _day(2026, 12, 11), null, _day(2026, 11, 20)],
      unit: FormulaUnit.date,
      name: 'Échéance',
    ),
    'valide': const FormulaSeries(
      [1, 0, 0, 1, 0, 1],
      filled: [true, false, false, true, false, true],
      name: 'Validé',
    ),
    'prix unitaire': const FormulaSeries([2.5, null, 10, null, null, 1]),
    'quantite': const FormulaSeries([1, 2, 3, 4, 5, 6]),
    'statut': const FormulaLabels([
      true,
      true,
      true,
      true,
      false,
      true,
    ], name: 'Statut'),
    'vide': const FormulaSeries([null, null]),
    'cassee': const FormulaBroken(name: 'Cassée'),
    'boucle': const FormulaBroken(name: 'Boucle', cyclic: true),
  };

  @override
  FormulaOperand? column(String name) => _columns[normalizeFormulaName(name)];
}

void main() {
  final engine = ExcelliumFormulaEngine();
  final scope = _Scope();

  FormulaOutcome run(String source) => engine.evaluate(source, scope);

  double? scalar(String source) {
    final outcome = run(source);
    expect(outcome, isA<FormulaScalar>(), reason: '$source → $outcome');
    return (outcome as FormulaScalar).value;
  }

  List<double?> column(String source) {
    final outcome = run(source);
    expect(outcome, isA<FormulaColumn>(), reason: '$source → $outcome');
    return (outcome as FormulaColumn).values;
  }

  FormulaError error(String source) {
    final outcome = run(source);
    expect(outcome, isA<FormulaFailure>(), reason: '$source → $outcome');
    return (outcome as FormulaFailure).error;
  }

  group('nombres et opérateurs', () {
    test('priorités, parenthèses et signe', () {
      expect(scalar('2 + 3 * 4'), 14);
      expect(scalar('(2 + 3) * 4'), 20);
      expect(scalar('10 - 4 - 3'), 3);
      expect(scalar('-3 + 5'), 2);
      expect(scalar('2 × 3 ÷ 4'), 1.5);
    });

    test('la virgule et le point sont des séparateurs décimaux', () {
      expect(scalar('12,5 * 2'), 25);
      expect(scalar('12.5 * 2'), 25);
    });

    test('une division par zéro ne donne pas de valeur', () {
      expect(scalar('4 / 0'), isNull);
      expect(column('Budget / 0'), everyElement(isNull));
    });

    test('un texte vide n\'est pas une erreur', () {
      expect(run('   '), isA<FormulaEmpty>());
    });
  });

  group('colonnes', () {
    test('une colonne seule donne une valeur par ligne', () {
      expect(column('Budget'), [1200, 850, 400, 600, 300, 950]);
    });

    test('le nom ne tient compte ni de la casse ni des accents', () {
      expect(column('budget'), column('BUDGET'));
      expect(scalar('Somme(duree)'), scalar('Somme(Durée)'));
    });

    test('un nom avec des espaces s\'écrit entre crochets', () {
      expect(scalar('Somme([Prix unitaire] * Quantite)'), 38.5);
    });

    test('une colonne se désigne aussi par sa lettre', () {
      expect(scalar('Somme(B)'), 4300);
    });

    test('une expression entre colonnes se calcule ligne à ligne', () {
      expect(column('Budget * (100 - Avancement) / 100'), [
        480,
        850,
        260,
        0,
        270,
        0,
      ]);
    });

    test('une cellule vide donne une ligne sans valeur', () {
      expect(column('[Prix unitaire] * 2'), [5, null, 20, null, null, 2]);
    });
  });

  group('fonctions de colonne', () {
    test('somme, moyenne, minimum, maximum', () {
      expect(scalar('Somme(Budget)'), 4300);
      expect(scalar('Moyenne(Budget)'), closeTo(716.67, 0.01));
      expect(scalar('Min(Budget)'), 300);
      expect(scalar('Max(Budget)'), 950 > 1200 ? 950 : 1200);
    });

    test('le résultat garde l\'unité de la colonne', () {
      expect((run('Somme(Durée)') as FormulaScalar).unit, FormulaUnit.duration);
      expect(
        (run('Moyenne(Avancement)') as FormulaScalar).unit,
        FormulaUnit.percent,
      );
      expect((run('Min(Échéance)') as FormulaScalar).unit, FormulaUnit.date);
    });

    test('min et max acceptent les dates', () {
      expect(
        scalar('Min(Échéance)'),
        DateTime.utc(2026, 11, 20).millisecondsSinceEpoch /
            Duration.millisecondsPerDay,
      );
    });

    test('Nombre compte les cellules renseignées de toute colonne', () {
      expect(scalar('Nombre(Statut)'), 5);
      expect(scalar('Nombre(Budget)'), 6);
      expect(scalar('Nombre([Prix unitaire])'), 3);
      // Une colonne Booléen compte ses cases cochées.
      expect(scalar('Nombre(Validé)'), 3);
      expect((run('Nombre(Durée)') as FormulaScalar).unit, FormulaUnit.number);
    });

    test('une fonction sur une expression', () {
      expect(
        scalar('Somme(Budget * Avancement) / Somme(Budget)'),
        closeTo(56.74, 0.01),
      );
      expect(scalar('Somme(Budget) - 1000'), 3300);
    });

    test('plusieurs colonnes donnent un résultat par colonne', () {
      final outcome = run('somme(budget; Durée)');
      expect(outcome, isA<FormulaMultiple>());
      expect((outcome as FormulaMultiple).parts, const [
        FormulaPart('Budget', 4300),
        FormulaPart('Durée', 22.5, FormulaUnit.duration),
      ]);
    });

    test(
      'un résultat multiple s\'étiquette par le texte d\'une expression',
      () {
        final outcome = run('Max(Budget * 2; Avancement)') as FormulaMultiple;
        expect(outcome.parts.map((p) => p.label), ['Budget * 2', 'Avancement']);
      },
    );

    test('une colonne vide ne donne pas de valeur', () {
      expect(scalar('Somme(Vide)'), isNull);
      expect(scalar('Moyenne(Vide)'), isNull);
      expect(scalar('Nombre(Vide)'), 0);
    });
  });

  group('fonctions de ligne', () {
    test('Arrondi à l\'entier ou à n décimales', () {
      expect(column('Arrondi(Budget / Durée)'), [185, 213, 178, 200, 171, 190]);
      expect(scalar('Arrondi(10 / 3; 2)'), 3.33);
    });

    test('Abs', () {
      expect(column('Abs(Budget - 800)'), [400, 50, 400, 200, 500, 150]);
    });

    test('le résultat garde l\'unité', () {
      expect(
        (run('Arrondi(Durée)') as FormulaColumn).unit,
        FormulaUnit.duration,
      );
    });
  });

  group('unités', () {
    test('une somme ou une différence de même unité la conserve', () {
      expect(
        (run('Durée + Durée') as FormulaColumn).unit,
        FormulaUnit.duration,
      );
      expect(
        (run('Avancement - 10') as FormulaColumn).unit,
        FormulaUnit.number,
      );
    });

    test('un produit ou un quotient donne un simple nombre', () {
      expect((run('Budget / Durée') as FormulaColumn).unit, FormulaUnit.number);
    });
  });

  group('erreurs', () {
    test('colonne ou fonction inconnue', () {
      expect(
        error('Somme(Prix)'),
        const FormulaError(FormulaErrorCode.unknownColumn, 'Prix'),
      );
      expect(
        error('Truc(Budget)'),
        const FormulaError(FormulaErrorCode.unknownFunction, 'Truc'),
      );
    });

    test('colonne non numérique dans un calcul', () {
      const expected = FormulaError(FormulaErrorCode.notNumeric, 'Statut');
      expect(error('Somme(Statut)'), expected);
      expect(error('Statut * 2'), expected);
      expect(error('Statut'), expected);
    });

    test('les dates ne se somment pas', () {
      expect(
        error('Somme(Échéance)').code,
        FormulaErrorCode.datesNotComputable,
      );
      expect(error('Échéance + 1').code, FormulaErrorCode.datesNotComputable);
    });

    test('un résultat multiple ne se combine pas', () {
      expect(
        error('Somme(Budget; Durée) * 2').code,
        FormulaErrorCode.multipleNotCombinable,
      );
    });

    test('parenthèses et crochets', () {
      expect(error('Somme(Budget').code, FormulaErrorCode.missingParenthesis);
      expect(error('(2 + 3').code, FormulaErrorCode.missingParenthesis);
      expect(
        error('Somme(Budget))'),
        const FormulaError(FormulaErrorCode.unexpectedToken, ')'),
      );
      expect(error('[Prix').code, FormulaErrorCode.missingBracket);
    });

    test('formule incomplète ou élément inattendu', () {
      expect(error('Budget +').code, FormulaErrorCode.incomplete);
      expect(
        error('Budget 2'),
        const FormulaError(FormulaErrorCode.unexpectedToken, '2'),
      );
      expect(
        error('Budget \$ 2'),
        const FormulaError(FormulaErrorCode.unexpectedCharacter, '\$'),
      );
      expect(
        error('Budget ; Durée').code,
        FormulaErrorCode.strayArgumentSeparator,
      );
    });

    test('paramètres d\'une fonction de ligne', () {
      expect(
        error('Abs(Budget; 2)'),
        const FormulaError(FormulaErrorCode.wrongArgumentCount, 'Abs'),
      );
      expect(
        error('Arrondi(Budget; Durée)'),
        const FormulaError(FormulaErrorCode.numberExpected, 'Arrondi'),
      );
    });

    test('colonne Formule en erreur ou en boucle', () {
      expect(
        error('Cassée * 2'),
        const FormulaError(FormulaErrorCode.brokenColumn, 'Cassée'),
      );
      expect(error('Boucle + 1').code, FormulaErrorCode.cyclic);
    });
  });

  group('extension', () {
    test('une fonction ajoutée au moteur est utilisable et annoncée', () {
      final extended = ExcelliumFormulaEngine(
        functions: [...standardFunctions, const _Median(), const _Double()],
      );

      expect(
        (extended.evaluate('Médiane(Budget)', scope) as FormulaScalar).value,
        725,
      );
      expect(
        (extended.evaluate('mediane(Budget)', scope) as FormulaScalar).value,
        725,
      );
      expect(
        (extended.evaluate('Double(Quantite)', scope) as FormulaColumn).values,
        [2, 4, 6, 8, 10, 12],
      );
      expect(
        extended.functions.map((f) => f.name),
        containsAll(['Médiane', 'Double']),
      );
      // Le moteur d'origine ne la connaît pas.
      expect(error('Médiane(Budget)').code, FormulaErrorCode.unknownFunction);
    });

    test('les fonctions d\'origine sont annoncées dans l\'ordre', () {
      expect(engine.functions.map((f) => f.name), [
        'Somme',
        'Moyenne',
        'Min',
        'Max',
        'Nombre',
        'Arrondi',
        'Abs',
      ]);
    });
  });
}

final class _Median extends ColumnFunction {
  const _Median();

  @override
  String get name => 'Médiane';

  @override
  String get example => 'Médiane(Budget)';

  @override
  double? compute(ColumnInput input) {
    if (input.numbers.isEmpty) return null;
    final sorted = [...input.numbers]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

final class _Double extends RowFunction {
  const _Double();

  @override
  String get name => 'Double';

  @override
  String get example => 'Double(Prix)';

  @override
  double? compute(double value, List<double> parameters) => value * 2;
}
