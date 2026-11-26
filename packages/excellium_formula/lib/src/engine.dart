import 'package:excellium_core/excellium_core.dart';

import 'functions.dart';
import 'standard_functions.dart';
import 'syntax.dart';

/// Le moteur de formules d'Excellium.
///
/// Langage : nombres (virgule décimale), noms de colonne (entre crochets
/// s'ils contiennent des espaces), `+ - × /`, parenthèses et fonctions.
/// Les fonctions sont celles de [functions] : en passer d'autres au
/// constructeur suffit à étendre le langage.
final class ExcelliumFormulaEngine implements FormulaEngine {
  ExcelliumFormulaEngine({List<FormulaFunction> functions = standardFunctions})
    : _functions = List.unmodifiable(functions),
      _byName = {
        for (final function in functions)
          for (final name in [function.name, ...function.aliases])
            normalizeFormulaName(name): function,
      };

  final List<FormulaFunction> _functions;
  final Map<String, FormulaFunction> _byName;

  @override
  List<FormulaFunctionInfo> get functions => [
    for (final function in _functions) function.info,
  ];

  @override
  FormulaOutcome evaluate(String source, FormulaScope scope) {
    if (source.trim().isEmpty) return const FormulaEmpty();
    try {
      final tree = Parser(source, tokenize(source)).parse();
      return switch (_Evaluation(this, source, scope).value(tree)) {
        _Number(:final value, :final unit) => FormulaScalar(value, unit),
        _Series(:final values, :final unit) => FormulaColumn(values, unit),
        _Many(:final parts) => FormulaMultiple(parts),
        _Words(:final name) => FormulaFailure(
          FormulaError(FormulaErrorCode.notNumeric, name),
        ),
      };
    } on FormulaException catch (exception) {
      return FormulaFailure(exception.error);
    }
  }
}

/// Valeur manipulée pendant le calcul.
sealed class _Value {
  const _Value();
}

/// Une seule valeur ; `null` quand il n'y a rien (division par zéro…).
final class _Number extends _Value {
  const _Number(this.value, [this.unit = FormulaUnit.number]);

  final double? value;
  final FormulaUnit unit;
}

/// Une valeur par ligne.
final class _Series extends _Value {
  const _Series(this.values, this.unit, {this.filled});

  final List<double?> values;
  final FormulaUnit unit;
  final List<bool>? filled;
}

/// Une colonne non numérique.
final class _Words extends _Value {
  const _Words(this.name, this.filledCount);

  final String name;
  final int filledCount;
}

/// Plusieurs résultats nommés.
final class _Many extends _Value {
  const _Many(this.parts);

  final List<FormulaPart> parts;
}

final class _Evaluation {
  const _Evaluation(this._engine, this._source, this._scope);

  final ExcelliumFormulaEngine _engine;
  final String _source;
  final FormulaScope _scope;

  _Value value(Node node) => switch (node) {
    NumberNode(:final value) => _Number(value),
    NameNode(:final name) => _column(name),
    NegateNode(:final operand) => _arithmetic(
      TokenKind.minus,
      const _Number(0),
      value(operand),
    ),
    BinaryNode(:final operator, :final left, :final right) => _arithmetic(
      operator,
      value(left),
      value(right),
    ),
    CallNode() => _call(node),
  };

  _Value _column(String name) => switch (_scope.column(name)) {
    null => fail(FormulaErrorCode.unknownColumn, name),
    FormulaSeries(:final values, :final unit, :final filled) => _Series(
      values,
      unit,
      filled: filled,
    ),
    FormulaLabels(:final name, :final filledCount) => _Words(name, filledCount),
    FormulaBroken(:final name, :final cyclic) => fail(
      cyclic ? FormulaErrorCode.cyclic : FormulaErrorCode.brokenColumn,
      name,
    ),
  };

  /// Vérifie qu'une valeur peut entrer dans un calcul numérique.
  _Value _numeric(_Value value) {
    switch (value) {
      case _Many():
        fail(FormulaErrorCode.multipleNotCombinable);
      case _Words(:final name):
        fail(FormulaErrorCode.notNumeric, name);
      case _Number(:final unit) || _Series(:final unit):
        if (unit == FormulaUnit.date) fail(FormulaErrorCode.datesNotComputable);
        return value;
    }
  }

  _Value _arithmetic(TokenKind operator, _Value left, _Value right) {
    final a = _numeric(left);
    final b = _numeric(right);
    double? apply(double? x, double? y) {
      if (x == null || y == null) return null;
      return switch (operator) {
        TokenKind.plus => x + y,
        TokenKind.minus => x - y,
        TokenKind.times => x * y,
        _ => y == 0 ? null : x / y,
      };
    }

    final unitA = _unitOf(a);
    final unitB = _unitOf(b);
    // Une somme ou une différence garde l'unité commune (des durées, des
    // pourcentages) ; un produit ou un quotient donne un simple nombre.
    final additive = operator == TokenKind.plus || operator == TokenKind.minus;
    final unit = additive && unitA == unitB ? unitA : FormulaUnit.number;

    if (a is _Number && b is _Number) {
      return _Number(apply(a.value, b.value), unit);
    }
    final length = a is _Series
        ? a.values.length
        : (b as _Series).values.length;
    return _Series([
      for (var i = 0; i < length; i++)
        apply(
          a is _Series ? a.values[i] : (a as _Number).value,
          b is _Series ? b.values[i] : (b as _Number).value,
        ),
    ], unit);
  }

  FormulaUnit _unitOf(_Value value) => switch (value) {
    _Number(:final unit) || _Series(:final unit) => unit,
    _ => FormulaUnit.number,
  };

  _Value _call(CallNode node) {
    final function = _engine._byName[normalizeFormulaName(node.function)];
    return switch (function) {
      null => fail(FormulaErrorCode.unknownFunction, node.function),
      ColumnFunction() => _columnCall(function, node),
      RowFunction() => _rowCall(function, node),
    };
  }

  /// Une fonction de colonne donne un résultat par argument.
  _Value _columnCall(ColumnFunction function, CallNode node) {
    final parts = <FormulaPart>[];
    for (final argument in node.arguments) {
      final result = _reduce(function, value(argument));
      parts.add(FormulaPart(_label(argument), result.value, result.unit));
    }
    return parts.length == 1
        ? _Number(parts.single.value, parts.single.unit)
        : _Many(parts);
  }

  _Number _reduce(ColumnFunction function, _Value value) {
    switch (value) {
      case _Many():
        fail(FormulaErrorCode.multipleNotCombinable);

      case _Words(:final name, :final filledCount):
        if (function.needsNumbers) fail(FormulaErrorCode.notNumeric, name);
        return _Number(
          function.compute(
            ColumnInput(numbers: const [], filledCount: filledCount),
          ),
          function.unitFor(FormulaUnit.number),
        );

      case _Number(value: final number, :final unit):
        _checkDates(function, unit);
        final numbers = [?number];
        return _Number(
          function.compute(
            ColumnInput(numbers: numbers, filledCount: numbers.length),
          ),
          function.unitFor(unit),
        );

      case _Series(:final values, :final unit, :final filled):
        _checkDates(function, unit);
        final numbers = values.nonNulls.toList();
        return _Number(
          function.compute(
            ColumnInput(
              numbers: numbers,
              filledCount: filled == null
                  ? numbers.length
                  : filled.where((f) => f).length,
            ),
          ),
          function.unitFor(unit),
        );
    }
  }

  void _checkDates(ColumnFunction function, FormulaUnit unit) {
    if (unit == FormulaUnit.date &&
        function.needsNumbers &&
        !function.acceptsDates) {
      fail(FormulaErrorCode.datesNotComputable);
    }
  }

  /// Une fonction de ligne s'applique à chaque valeur du premier argument ;
  /// les arguments suivants sont de simples nombres.
  _Value _rowCall(RowFunction function, CallNode node) {
    final extra = node.arguments.length - 1;
    if (extra < function.minParameters || extra > function.maxParameters) {
      fail(FormulaErrorCode.wrongArgumentCount, function.name);
    }
    final subject = _numeric(value(node.arguments.first));
    final parameters = <double>[];
    for (final argument in node.arguments.skip(1)) {
      final parameter = value(argument);
      if (parameter is! _Number || parameter.value == null) {
        fail(FormulaErrorCode.numberExpected, function.name);
      }
      parameters.add(parameter.value!);
    }
    double? apply(double? x) =>
        x == null ? null : function.compute(x, parameters);

    return switch (subject) {
      _Number(:final value, :final unit) => _Number(apply(value), unit),
      _Series(:final values, :final unit) => _Series([
        for (final value in values) apply(value),
      ], unit),
      _ => subject,
    };
  }

  /// Étiquette d'un résultat : le nom exact de la colonne quand l'argument
  /// en est une, sinon le texte écrit.
  String _label(Node argument) {
    if (argument is NameNode) {
      final column = _scope.column(argument.name);
      if (column is FormulaSeries && column.name.isNotEmpty) return column.name;
      if (column is FormulaLabels) return column.name;
    }
    return _source.substring(argument.start, argument.end).trim();
  }
}
