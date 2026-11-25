import '../model/cell_value.dart';
import '../model/column.dart';

/// Raison pour laquelle une saisie a été refusée. L'interface se charge du
/// message affiché.
enum CellInputError {
  notANumber,
  notADate,
  notADuration,
  notABoolean,

  /// Le type ne se saisit pas au clavier (une référence se choisit).
  notTypable,
}

/// Résultat de l'interprétation d'une saisie.
sealed class CellInputResult {
  const CellInputResult();
}

/// Saisie acceptée ; [value] vaut `null` quand la saisie vide la cellule.
final class CellInputOk extends CellInputResult {
  const CellInputOk(this.value);

  final CellValue? value;
}

final class CellInputRejected extends CellInputResult {
  const CellInputRejected(this.error);

  final CellInputError error;
}

/// Interprète un texte saisi par l'utilisateur selon le type de la colonne.
///
/// Les conventions sont françaises : virgule décimale, dates `JJ/MM/AAAA`,
/// durées `1:30`, `1 h 30` ou `45 min`.
CellInputResult parseCellInput(ColumnType type, String input) {
  final text = input.trim();
  if (text.isEmpty) return const CellInputOk(null);

  switch (type) {
    case ColumnType.text:
      return CellInputOk(TextValue(text));

    case ColumnType.number:
    case ColumnType.percent:
      final number = _parseNumber(
        type == ColumnType.percent ? text.replaceAll('%', '') : text,
      );
      return number == null
          ? const CellInputRejected(CellInputError.notANumber)
          : CellInputOk(NumberValue(number));

    case ColumnType.date:
      final date = _parseDate(text);
      return date == null
          ? const CellInputRejected(CellInputError.notADate)
          : CellInputOk(date);

    case ColumnType.duration:
      final duration = _parseDuration(text);
      return duration == null
          ? const CellInputRejected(CellInputError.notADuration)
          : CellInputOk(DurationValue(duration));

    case ColumnType.singleCategory:
      return CellInputOk(CategoryValue.single(text));

    case ColumnType.multiCategory:
      final seen = <String>{};
      final categories = [
        for (final part in text.split(RegExp('[,;]')))
          if (part.trim().isNotEmpty && seen.add(part.trim())) part.trim(),
      ];
      return CellInputOk(categories.isEmpty ? null : CategoryValue(categories));

    case ColumnType.boolean:
      final value = _parseBool(text);
      return value == null
          ? const CellInputRejected(CellInputError.notABoolean)
          : CellInputOk(BoolValue(value));

    case ColumnType.reference:
      return const CellInputRejected(CellInputError.notTypable);
  }
}

/// Texte à placer dans un champ de saisie pour modifier [value]. C'est
/// l'inverse de [parseCellInput] ; une référence n'a pas de forme texte.
String cellInputText(CellValue? value) => switch (value) {
  null => '',
  TextValue(:final text) => text,
  NumberValue(:final number) => formatNumber(number),
  DateValue(:final date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year.toString().padLeft(4, '0')}',
  DurationValue(:final duration) =>
    '${duration.inHours}:${_two(duration.inMinutes.remainder(60))}',
  CategoryValue(:final categories) => categories.join(', '),
  BoolValue(:final value) => value ? 'vrai' : 'faux',
  ReferenceValue() => '',
};

/// Écrit un nombre avec la virgule décimale et sans zéros inutiles.
String formatNumber(double number) {
  if (number == number.roundToDouble() && number.abs() < 1e15) {
    return number.toInt().toString();
  }
  return number.toString().replaceAll('.', ',');
}

/// Convertit une valeur vers un autre type de colonne, par exemple quand
/// l'utilisateur change le type. Renvoie `null` si la valeur n'a pas de sens
/// dans le nouveau type.
CellValue? convertCellValue(CellValue? value, ColumnType target) {
  if (value == null) return null;
  if (value.fits(target)) return value;
  if (value is CategoryValue && target == ColumnType.singleCategory) {
    return CategoryValue.single(value.categories.first);
  }
  final result = parseCellInput(target, cellInputText(value));
  return switch (result) {
    CellInputOk(:final value) => value,
    CellInputRejected() => null,
  };
}

String _two(int n) => n.toString().padLeft(2, '0');

double? _parseNumber(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');
  if (!RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)$').hasMatch(cleaned)) return null;
  final value = double.tryParse(cleaned);
  return (value == null || !value.isFinite) ? null : value;
}

DateValue? _parseDate(String input) {
  final iso = DateValue.tryParseIso(input);
  if (iso != null) return iso;
  final match = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})$')
      .firstMatch(input);
  if (match == null) return null;
  final day = match.group(1)!.padLeft(2, '0');
  final month = match.group(2)!.padLeft(2, '0');
  return DateValue.tryParseIso('${match.group(3)}-$month-$day');
}

Duration? _parseDuration(String input) {
  final text = input.toLowerCase().replaceAll(RegExp(r'[\s  ]'), '');

  // 1:30
  var match = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(text);
  if (match != null) {
    final minutes = int.parse(match.group(2)!);
    if (minutes > 59) return null;
    return Duration(hours: int.parse(match.group(1)!), minutes: minutes);
  }

  // 1h30, 1h, 2h05
  match = RegExp(r'^(\d+)h(\d{1,2})?(?:min|m)?$').firstMatch(text);
  if (match != null) {
    final minutes = int.parse(match.group(2) ?? '0');
    if (minutes > 59) return null;
    return Duration(hours: int.parse(match.group(1)!), minutes: minutes);
  }

  // 45min, 45m
  match = RegExp(r'^(\d+)(?:min|m)$').firstMatch(text);
  if (match != null) return Duration(minutes: int.parse(match.group(1)!));

  return null;
}

bool? _parseBool(String input) => switch (input.toLowerCase()) {
  'vrai' || 'oui' || 'true' || '1' || 'x' => true,
  'faux' || 'non' || 'false' || '0' => false,
  _ => null,
};
