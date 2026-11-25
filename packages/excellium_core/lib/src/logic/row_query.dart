import 'package:collection/collection.dart';

import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/query.dart';
import '../model/row.dart';

/// Donne le libellé d'une ligne référencée, pour trier une colonne Référence.
typedef ReferenceLabel = String Function(RowId rowId);

/// Applique les filtres puis le tri de [query] à [rows].
///
/// Les lignes sont rendues dans un nouvel ordre sans être modifiées : leur
/// `position` d'origine est conservée. Dès qu'un filtre est actif, les lignes
/// entièrement vides sont masquées. Les cellules vides de la colonne triée
/// sont placées à la fin, quel que soit le sens du tri.
List<SheetRow> applyRowQuery(
  List<SheetRow> rows,
  List<ColumnDef> columns,
  RowQuery query, {
  ReferenceLabel? referenceLabel,
}) {
  final byId = {for (final column in columns) column.id: column};
  final filters = [
    for (final entry in query.activeFilters.entries)
      if (byId[entry.key] case final column?) (column, entry.value),
  ];

  var result = rows.sortedBy<num>((row) => row.position);

  if (filters.isNotEmpty) {
    result = [
      for (final row in result)
        if (!row.isEmpty &&
            filters.every((f) => _matches(row[f.$1.id], f.$1, f.$2)))
          row,
    ];
  }

  final sort = query.sort;
  final sortColumn = sort == null ? null : byId[sort.columnId];
  if (sort == null || sortColumn == null) return result;

  final withKey = <(SheetRow, Comparable<Object>)>[];
  final withoutKey = <SheetRow>[];
  for (final row in result) {
    final key = _sortKey(row[sortColumn.id], sortColumn, row, referenceLabel);
    if (key == null) {
      withoutKey.add(row);
    } else {
      withKey.add((row, key));
    }
  }
  final direction = sort.ascending ? 1 : -1;
  withKey.sort((a, b) {
    final byKey = a.$2.compareTo(b.$2) * direction;
    return byKey != 0 ? byKey : a.$1.position.compareTo(b.$1.position);
  });
  return [for (final entry in withKey) entry.$1, ...withoutKey];
}

bool _matches(CellValue? value, ColumnDef column, FilterSpec filter) {
  switch (filter) {
    case TextContains(:final query):
      return value is TextValue &&
          value.text.toLowerCase().contains(query.trim().toLowerCase());

    case NumberRange(:final min, :final max):
      if (value is! NumberValue) return false;
      return (min == null || value.number >= min) &&
          (max == null || value.number <= max);

    case DateRange(:final from, :final to):
      if (value is! DateValue) return false;
      return (from == null || !value.date.isBefore(from.date)) &&
          (to == null || !value.date.isAfter(to.date));

    case DurationRange(:final min, :final max):
      if (value is! DurationValue) return false;
      return (min == null || value.duration >= min) &&
          (max == null || value.duration <= max);

    case CategoryAnyOf(:final categories):
      return value is CategoryValue &&
          value.categories.any(categories.contains);

    case BoolIs(value: final expected):
      final actual = value is BoolValue && value.value;
      return actual == expected;

    case ReferenceAnyOf(:final rowIds):
      return value is ReferenceValue && value.rowIds.any(rowIds.contains);
  }
}

Comparable<Object>? _sortKey(
  CellValue? value,
  ColumnDef column,
  SheetRow row,
  ReferenceLabel? referenceLabel,
) {
  // Une case non cochée est une vraie valeur pour une ligne qui a des
  // données ; on ne la relègue pas avec les cellules vides.
  if (column.type == ColumnType.boolean) {
    if (row.isEmpty) return null;
    return _Key<num>((value is BoolValue && value.value) ? 1 : 0);
  }
  return switch (value) {
    null => null,
    TextValue(:final text) => _Key<String>(text.toLowerCase()),
    NumberValue(:final number) => _Key<num>(number),
    DateValue(:final date) => _Key<num>(date.millisecondsSinceEpoch),
    DurationValue(:final duration) => _Key<num>(duration.inMicroseconds),
    CategoryValue(:final categories) => _Key<String>(
      categories.join(', ').toLowerCase(),
    ),
    BoolValue(:final value) => _Key<num>(value ? 1 : 0),
    ReferenceValue(:final rowIds) => _Key<String>(
      rowIds
          .map((id) => referenceLabel?.call(id) ?? id.value)
          .join(', ')
          .toLowerCase(),
    ),
  };
}

/// Clé de tri homogène : toutes les clés d'une même colonne ont le même type.
final class _Key<T extends Comparable<Object>> implements Comparable<Object> {
  const _Key(this.value);

  final T value;

  @override
  int compareTo(Object other) => value.compareTo((other as _Key<T>).value);
}
