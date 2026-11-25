import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'column.dart';
import 'ids.dart';

/// Valeur typée d'une cellule. Une cellule vide n'a pas de valeur (`null`).
@immutable
sealed class CellValue {
  const CellValue();

  /// Indique si cette valeur peut être stockée dans une colonne de ce type.
  bool fits(ColumnType type);
}

final class TextValue extends CellValue {
  const TextValue(this.text);

  final String text;

  @override
  bool fits(ColumnType type) => type == ColumnType.text;

  @override
  bool operator ==(Object other) => other is TextValue && other.text == text;

  @override
  int get hashCode => Object.hash(TextValue, text);

  @override
  String toString() => 'TextValue($text)';
}

/// Nombre, utilisé par les colonnes Nombre et Pourcentage. Pour un
/// pourcentage, 12.5 signifie 12,5 %.
final class NumberValue extends CellValue {
  const NumberValue(this.number);

  final double number;

  @override
  bool fits(ColumnType type) =>
      type == ColumnType.number || type == ColumnType.percent;

  @override
  bool operator ==(Object other) =>
      other is NumberValue && other.number == number;

  @override
  int get hashCode => Object.hash(NumberValue, number);

  @override
  String toString() => 'NumberValue($number)';
}

/// Date du calendrier, sans heure ni fuseau.
final class DateValue extends CellValue {
  DateValue(int year, int month, int day)
    : date = DateTime.utc(year, month, day);

  DateValue.fromDateTime(DateTime value)
    : date = DateTime.utc(value.year, value.month, value.day);

  /// Minuit UTC du jour concerné.
  final DateTime date;

  /// Forme ISO `AAAA-MM-JJ`.
  String get iso =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Lit une date ISO `AAAA-MM-JJ`, ou renvoie `null`.
  static DateValue? tryParseIso(String input) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final value = DateValue(year, month, day);
    // DateTime normalise les dates impossibles (31 février) : on les refuse.
    final same =
        value.date.year == year &&
        value.date.month == month &&
        value.date.day == day;
    return same ? value : null;
  }

  @override
  bool fits(ColumnType type) => type == ColumnType.date;

  @override
  bool operator ==(Object other) => other is DateValue && other.date == date;

  @override
  int get hashCode => Object.hash(DateValue, date);

  @override
  String toString() => 'DateValue($iso)';
}

final class DurationValue extends CellValue {
  const DurationValue(this.duration);

  final Duration duration;

  @override
  bool fits(ColumnType type) => type == ColumnType.duration;

  @override
  bool operator ==(Object other) =>
      other is DurationValue && other.duration == duration;

  @override
  int get hashCode => Object.hash(DurationValue, duration);

  @override
  String toString() => 'DurationValue($duration)';
}

/// Une ou plusieurs catégories. Une colonne « catégorie unique » n'en
/// contient qu'une.
final class CategoryValue extends CellValue {
  CategoryValue(Iterable<String> categories)
    : categories = List.unmodifiable(categories);

  CategoryValue.single(String category)
    : categories = List.unmodifiable([category]);

  final List<String> categories;

  @override
  bool fits(ColumnType type) =>
      type == ColumnType.multiCategory ||
      (type == ColumnType.singleCategory && categories.length == 1);

  @override
  bool operator ==(Object other) =>
      other is CategoryValue &&
      const ListEquality<String>().equals(other.categories, categories);

  @override
  int get hashCode =>
      Object.hash(CategoryValue, const ListEquality<String>().hash(categories));

  @override
  String toString() => 'CategoryValue($categories)';
}

final class BoolValue extends CellValue {
  // ignore: avoid_positional_boolean_parameters
  const BoolValue(this.value);

  final bool value;

  @override
  bool fits(ColumnType type) => type == ColumnType.boolean;

  @override
  bool operator ==(Object other) => other is BoolValue && other.value == value;

  @override
  int get hashCode => Object.hash(BoolValue, value);

  @override
  String toString() => 'BoolValue($value)';
}

/// Référence vers une ou plusieurs lignes d'une autre feuille.
final class ReferenceValue extends CellValue {
  ReferenceValue(Iterable<RowId> rowIds) : rowIds = List.unmodifiable(rowIds);

  final List<RowId> rowIds;

  @override
  bool fits(ColumnType type) => type == ColumnType.reference;

  @override
  bool operator ==(Object other) =>
      other is ReferenceValue &&
      const ListEquality<RowId>().equals(other.rowIds, rowIds);

  @override
  int get hashCode =>
      Object.hash(ReferenceValue, const ListEquality<RowId>().hash(rowIds));

  @override
  String toString() => 'ReferenceValue($rowIds)';
}
