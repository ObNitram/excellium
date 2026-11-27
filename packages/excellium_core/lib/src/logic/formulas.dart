import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import '../ports/formula.dart';

/// Nom de colonne ou de fonction sous sa forme comparable : sans accents,
/// sans majuscules, sans espaces autour. `Échéance` et `echeance` désignent
/// la même colonne.
String normalizeFormulaName(String name) {
  final buffer = StringBuffer();
  for (final rune in name.trim().toLowerCase().runes) {
    buffer.write(_plain[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

final Map<int, String> _plain = {
  for (final entry in const {
    'a': 'àâäáãå',
    'c': 'ç',
    'e': 'éèêë',
    'i': 'îïíì',
    'n': 'ñ',
    'o': 'ôöóòõ',
    'u': 'ùûüú',
    'y': 'ÿý',
    'oe': 'œ',
    'ae': 'æ',
  }.entries)
    for (final rune in entry.value.runes) rune: entry.key,
};

/// Valeurs d'une colonne Formule, ligne par ligne.
final class FormulaColumnValues {
  const FormulaColumnValues({
    this.unit = FormulaUnit.number,
    this.values = const {},
    this.error,
  });

  final FormulaUnit unit;

  /// Résultat par ligne ; une ligne sans résultat est absente.
  final Map<RowId, double> values;

  /// Renseigné quand la formule est refusée : aucune ligne n'a de valeur.
  final FormulaError? error;

  bool get hasError => error != null;
}

/// Une case de calcul contient un texte libre, ou un calcul qui commence par
/// ce signe.
const String calcPrefix = '=';

/// Contenu d'une case de calcul, une fois interprété.
sealed class CalcCell {
  const CalcCell();
}

final class CalcBlank extends CalcCell {
  const CalcBlank();
}

/// Un simple texte, par exemple le libellé « Total ».
final class CalcText extends CalcCell {
  const CalcText(this.text);

  final String text;
}

/// Le résultat d'un calcul ; jamais un [FormulaEmpty].
final class CalcResult extends CalcCell {
  const CalcResult(this.outcome);

  final FormulaOutcome outcome;
}

/// Calculs d'une feuille : les colonnes Formule et les cases de calcul.
///
/// Fait le lien entre le modèle (colonnes, lignes, cellules) et le moteur de
/// formules, qui ne connaît que des séries de nombres. Les calculs portent
/// sur les lignes renseignées de la feuille ; une ligne entièrement vide n'a
/// pas de résultat.
final class SheetFormulas {
  SheetFormulas({
    required this.engine,
    required this.columns,
    required List<SheetRow> rows,
  }) : _rows = [
         for (final row in rows)
           if (!row.isEmpty) row,
       ];

  final FormulaEngine engine;
  final List<ColumnDef> columns;

  /// Les lignes renseignées, dans l'ordre de la feuille.
  final List<SheetRow> _rows;

  final Map<ColumnId, FormulaColumnValues> _cache = {};
  final Set<ColumnId> _resolving = {};

  /// Les fonctions du moteur, pour l'aide à la saisie.
  List<FormulaFunctionInfo> get functions => engine.functions;

  /// Valeurs de la colonne Formule [columnId].
  FormulaColumnValues column(ColumnId columnId) {
    final cached = _cache[columnId];
    if (cached != null) return cached;
    ColumnDef? column;
    for (final candidate in columns) {
      if (candidate.id == columnId) column = candidate;
    }
    if (column == null || column.type != ColumnType.formula) {
      return const FormulaColumnValues();
    }
    // Une formule peut citer une autre colonne Formule : elles se résolvent
    // à la demande, et une boucle est une erreur.
    if (!_resolving.add(columnId)) {
      return const FormulaColumnValues(
        error: FormulaError(FormulaErrorCode.cyclic),
      );
    }
    final outcome = engine.evaluate(column.formula, _Scope(this, _rows));
    _resolving.remove(columnId);

    final result = switch (outcome) {
      FormulaEmpty() => const FormulaColumnValues(),
      FormulaFailure(:final error) => FormulaColumnValues(error: error),
      FormulaColumn(:final values, :final unit) => FormulaColumnValues(
        unit: unit,
        values: {
          for (final (index, row) in _rows.indexed) row.id: ?values[index],
        },
      ),
      // Une valeur unique vaut pour chaque ligne : `Somme(Budget)`.
      FormulaScalar(:final value, :final unit) => FormulaColumnValues(
        unit: unit,
        values: value == null
            ? const {}
            : {for (final row in _rows) row.id: value},
      ),
      FormulaMultiple() => const FormulaColumnValues(
        error: FormulaError(FormulaErrorCode.multipleNotCombinable),
      ),
    };
    _cache[columnId] = result;
    return result;
  }

  /// Valeur de [column] sur [row] si c'est une colonne Formule calculable.
  double? valueAt(ColumnDef column, SheetRow row) =>
      column.type == ColumnType.formula
      ? this.column(column.id).values[row.id]
      : null;

  /// Évalue une formule sur [rows] (par défaut, toute la feuille). Les
  /// fonctions de colonne (`Somme`…) ne voient que ces lignes.
  FormulaOutcome evaluate(String source, {Iterable<SheetRow>? rows}) {
    final scoped = rows == null
        ? _rows
        : [
            for (final row in rows)
              if (!row.isEmpty) row,
          ];
    return engine.evaluate(source, _Scope(this, scoped));
  }

  /// Interprète le contenu d'une case de calcul : vide, texte, ou calcul
  /// commençant par `=` évalué sur [rows].
  CalcCell calcCell(String content, {Iterable<SheetRow>? rows}) {
    final text = content.trim();
    if (text.isEmpty) return const CalcBlank();
    if (!text.startsWith(calcPrefix)) return CalcText(text);
    final outcome = evaluate(text.substring(calcPrefix.length), rows: rows);
    return CalcResult(
      outcome is FormulaEmpty
          ? const FormulaFailure(FormulaError(FormulaErrorCode.incomplete))
          : outcome,
    );
  }

  FormulaOperand? _operand(String name, List<SheetRow> rows) {
    final key = normalizeFormulaName(name);
    ColumnDef? column;
    for (final candidate in columns) {
      if (candidate.name.trim().isNotEmpty &&
          normalizeFormulaName(candidate.name) == key) {
        column = candidate;
        break;
      }
    }
    if (column == null) {
      for (final candidate in columns) {
        if (normalizeFormulaName(candidate.letter) == key) {
          column = candidate;
          break;
        }
      }
    }
    if (column == null) return null;
    final id = column.id;

    switch (column.type) {
      case ColumnType.number:
      case ColumnType.percent:
        return FormulaSeries(
          [
            for (final row in rows)
              switch (row[id]) {
                NumberValue(:final number) => number,
                _ => null,
              },
          ],
          unit: column.type == ColumnType.percent
              ? FormulaUnit.percent
              : FormulaUnit.number,
          name: column.label,
        );

      case ColumnType.duration:
        return FormulaSeries(
          [
            for (final row in rows)
              switch (row[id]) {
                DurationValue(:final duration) =>
                  duration.inMicroseconds / Duration.microsecondsPerHour,
                _ => null,
              },
          ],
          unit: FormulaUnit.duration,
          name: column.label,
        );

      case ColumnType.date:
        return FormulaSeries(
          [
            for (final row in rows)
              switch (row[id]) {
                DateValue(:final date) =>
                  date.millisecondsSinceEpoch / Duration.millisecondsPerDay,
                _ => null,
              },
          ],
          unit: FormulaUnit.date,
          name: column.label,
        );

      case ColumnType.boolean:
        final checked = [
          for (final row in rows)
            switch (row[id]) {
              BoolValue(:final value) => value,
              _ => false,
            },
        ];
        return FormulaSeries(
          [for (final value in checked) value ? 1.0 : 0.0],
          filled: checked,
          name: column.label,
        );

      case ColumnType.text:
      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
      case ColumnType.reference:
        return FormulaLabels([
          for (final row in rows) row[id] != null,
        ], name: column.label);

      case ColumnType.formula:
        final computed = this.column(id);
        if (computed.hasError) {
          return FormulaBroken(
            name: column.label,
            cyclic: computed.error!.code == FormulaErrorCode.cyclic,
          );
        }
        return FormulaSeries(
          [for (final row in rows) computed.values[row.id]],
          unit: computed.unit,
          name: column.label,
        );
    }
  }
}

final class _Scope implements FormulaScope {
  const _Scope(this._owner, this._rows);

  final SheetFormulas _owner;
  final List<SheetRow> _rows;

  @override
  FormulaOperand? column(String name) => _owner._operand(name, _rows);
}

/// Valeur de cellule équivalente à un résultat de formule, pour l'afficher
/// avec les mêmes règles que les cellules saisies. Le nombre est arrondi à
/// deux décimales, la durée à la minute.
({CellValue value, ColumnType type})? formulaAsCell(
  double? value,
  FormulaUnit unit,
) {
  if (value == null || !value.isFinite) return null;
  switch (unit) {
    case FormulaUnit.number:
    case FormulaUnit.percent:
      final rounded = (value * 100).roundToDouble() / 100;
      return (
        value: NumberValue(rounded == 0 ? 0 : rounded),
        type: unit == FormulaUnit.percent
            ? ColumnType.percent
            : ColumnType.number,
      );
    case FormulaUnit.duration:
      return (
        value: DurationValue(Duration(minutes: (value * 60).round())),
        type: ColumnType.duration,
      );
    case FormulaUnit.date:
      final day = DateTime.fromMillisecondsSinceEpoch(
        (value * Duration.millisecondsPerDay).round(),
        isUtc: true,
      );
      return (value: DateValue.fromDateTime(day), type: ColumnType.date);
  }
}
