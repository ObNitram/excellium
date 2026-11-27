import 'dart:math' as math;

import 'package:excellium_core/excellium_core.dart';

import 'functions.dart';

/// Les fonctions fournies d'origine, dans l'ordre où l'aide les propose.
const List<FormulaFunction> standardFunctions = [
  SumFunction(),
  AverageFunction(),
  MinFunction(),
  MaxFunction(),
  CountFunction(),
  RoundFunction(),
  AbsFunction(),
];

final class SumFunction extends ColumnFunction {
  const SumFunction();

  @override
  String get name => 'Somme';

  @override
  String get example => 'Somme(Budget)';

  @override
  double? compute(ColumnInput input) => input.numbers.isEmpty
      ? null
      : input.numbers.fold<double>(0, (sum, value) => sum + value);
}

final class AverageFunction extends ColumnFunction {
  const AverageFunction();

  @override
  String get name => 'Moyenne';

  @override
  String get example => 'Moyenne(Budget)';

  @override
  double? compute(ColumnInput input) => input.numbers.isEmpty
      ? null
      : input.numbers.fold<double>(0, (sum, value) => sum + value) /
            input.numbers.length;
}

final class MinFunction extends ColumnFunction {
  const MinFunction();

  @override
  String get name => 'Min';

  @override
  String get example => 'Min(Échéance)';

  @override
  bool get acceptsDates => true;

  @override
  double? compute(ColumnInput input) =>
      input.numbers.isEmpty ? null : input.numbers.reduce(math.min);
}

final class MaxFunction extends ColumnFunction {
  const MaxFunction();

  @override
  String get name => 'Max';

  @override
  String get example => 'Max(Échéance)';

  @override
  bool get acceptsDates => true;

  @override
  double? compute(ColumnInput input) =>
      input.numbers.isEmpty ? null : input.numbers.reduce(math.max);
}

/// Compte les cellules renseignées, quel que soit le type de la colonne.
final class CountFunction extends ColumnFunction {
  const CountFunction();

  @override
  String get name => 'Nombre';

  @override
  String get example => 'Nombre(Statut)';

  @override
  bool get needsNumbers => false;

  @override
  FormulaUnit unitFor(FormulaUnit unit) => FormulaUnit.number;

  @override
  double? compute(ColumnInput input) => input.filledCount.toDouble();
}

/// `Arrondi(x)` à l'entier, `Arrondi(x; n)` à n décimales.
final class RoundFunction extends RowFunction {
  const RoundFunction();

  @override
  String get name => 'Arrondi';

  @override
  String get example => 'Arrondi(Prix; 2)';

  @override
  int get maxParameters => 1;

  @override
  double? compute(double value, List<double> parameters) {
    final digits = parameters.isEmpty
        ? 0
        : parameters.first.round().clamp(0, 6);
    final factor = math.pow(10, digits);
    return (value * factor).roundToDouble() / factor;
  }
}

final class AbsFunction extends RowFunction {
  const AbsFunction();

  @override
  String get name => 'Abs';

  @override
  String get example => 'Abs(Écart)';

  @override
  double? compute(double value, List<double> parameters) => value.abs();
}
