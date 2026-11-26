import 'dart:convert';

import 'package:excellium_core/excellium_core.dart';

/// Écrit et relit les valeurs de cellule et les paramètres de colonne en JSON.
///
/// Le format est propre à ce moteur de stockage : un autre backend peut
/// choisir le sien.

String encodeCellValue(CellValue value) => jsonEncode(switch (value) {
  TextValue(:final text) => {'t': 'text', 'v': text},
  NumberValue(:final number) => {'t': 'number', 'v': number},
  DateValue(:final iso) => {'t': 'date', 'v': iso},
  DurationValue(:final duration) => {
    't': 'duration',
    'v': duration.inMicroseconds,
  },
  CategoryValue(:final categories) => {'t': 'category', 'v': categories},
  BoolValue(:final value) => {'t': 'bool', 'v': value},
  ReferenceValue(:final rowIds) => {
    't': 'reference',
    'v': [for (final id in rowIds) id.value],
  },
});

/// Renvoie `null` si [source] n'est pas une valeur reconnue, plutôt que de
/// faire échouer la lecture de toute la feuille.
CellValue? decodeCellValue(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  final v = decoded['v'];
  return switch (decoded['t']) {
    'text' when v is String => TextValue(v),
    'number' when v is num => NumberValue(v.toDouble()),
    'date' when v is String => DateValue.tryParseIso(v),
    'duration' when v is int => DurationValue(Duration(microseconds: v)),
    'category' when v is List<Object?> => CategoryValue(v.whereType<String>()),
    'bool' when v is bool => BoolValue(v),
    'reference' when v is List<Object?> => ReferenceValue(
      v.whereType<String>().map(RowId.new),
    ),
    _ => null,
  };
}

String encodeReferenceConfig(ReferenceConfig config) => jsonEncode({
  'target': config.targetSheetId?.value,
  'cardinality': config.cardinality.name,
  'search': [for (final id in config.searchColumnIds) id.value],
});

ReferenceConfig decodeReferenceConfig(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return const ReferenceConfig();
  }
  if (decoded is! Map<String, Object?>) return const ReferenceConfig();
  final target = decoded['target'];
  final search = decoded['search'];
  return ReferenceConfig(
    targetSheetId: target is String ? SheetId(target) : null,
    cardinality:
        Cardinality.values.asNameMap()[decoded['cardinality']] ??
        Cardinality.one,
    searchColumnIds: search is List<Object?>
        ? [for (final id in search.whereType<String>()) ColumnId(id)]
        : const [],
  );
}

/// Type inconnu (base écrite par une version plus récente) : on retombe sur
/// Texte pour que la feuille reste lisible.
ColumnType decodeColumnType(String name) =>
    ColumnType.values.asNameMap()[name] ?? ColumnType.text;

String? encodeCellStyle(CellStyle style) => style.isEmpty
    ? null
    : jsonEncode({
        if (style.bold != null) 'bold': style.bold,
        if (style.italic != null) 'italic': style.italic,
        if (style.underline != null) 'underline': style.underline,
        if (style.align != null) 'align': style.align!.name,
        if (style.boolDisplay != null) 'bool': style.boolDisplay!.name,
        if (style.percentDisplay != null) 'percent': style.percentDisplay!.name,
      });

CellStyle decodeCellStyle(String? source) {
  final map = _decodeMap(source);
  if (map == null) return CellStyle.none;
  bool? flag(String key) => map[key] is bool ? map[key]! as bool : null;
  return CellStyle(
    bold: flag('bold'),
    italic: flag('italic'),
    underline: flag('underline'),
    align: TextAlignment.values.asNameMap()[map['align']],
    boolDisplay: BoolDisplay.values.asNameMap()[map['bool']],
    percentDisplay: PercentDisplay.values.asNameMap()[map['percent']],
  );
}

String? encodeOptions(List<String> options) =>
    options.isEmpty ? null : jsonEncode(options);

List<String> decodeOptions(String? source) {
  if (source == null) return const [];
  try {
    final decoded = jsonDecode(source);
    return decoded is List<Object?>
        ? decoded.whereType<String>().toList()
        : const [];
  } on FormatException {
    return const [];
  }
}

String encodeViewSpec(ViewSpec spec) => jsonEncode({
  'layout': spec.layout.kind.name,
  'key': spec.layout.keyColumnId?.value,
  'sort': spec.query.sort == null
      ? null
      : {
          'column': spec.query.sort!.columnId.value,
          'ascending': spec.query.sort!.ascending,
        },
  'filters': {
    for (final entry in spec.query.filters.entries)
      entry.key.value: _encodeFilter(entry.value),
  },
  'hidden': [for (final id in spec.hiddenColumnIds) id.value],
});

/// Une vue illisible redevient la vue complète, plutôt que de bloquer la
/// feuille.
ViewSpec decodeViewSpec(String source) {
  final map = _decodeMap(source);
  if (map == null) return ViewSpec.full;
  final key = map['key'];
  final sort = map['sort'];
  final filters = map['filters'];
  final hidden = map['hidden'];
  return ViewSpec(
    layout: ViewLayout(
      LayoutKind.values.asNameMap()[map['layout']] ?? LayoutKind.grid,
      key is String ? ColumnId(key) : null,
    ),
    query: RowQuery(
      sort: sort is Map<String, Object?> && sort['column'] is String
          ? SortSpec(
              ColumnId(sort['column']! as String),
              ascending: sort['ascending'] != false,
            )
          : null,
      filters: {
        if (filters is Map<String, Object?>)
          for (final entry in filters.entries)
            ColumnId(entry.key): ?_decodeFilter(entry.value),
      },
    ),
    hiddenColumnIds: hidden is List<Object?>
        ? hidden.whereType<String>().map(ColumnId.new)
        : const [],
  );
}

Map<String, Object?> _encodeFilter(FilterSpec filter) => switch (filter) {
  TextContains(:final query) => {'t': 'text', 'query': query},
  NumberRange(:final min, :final max) => {
    't': 'number',
    'min': min,
    'max': max,
  },
  DateRange(:final from, :final to) => {
    't': 'date',
    'from': from?.iso,
    'to': to?.iso,
  },
  DurationRange(:final min, :final max) => {
    't': 'duration',
    'min': min?.inMicroseconds,
    'max': max?.inMicroseconds,
  },
  CategoryAnyOf(:final categories) => {
    't': 'category',
    'values': categories.toList(),
  },
  BoolIs(:final value) => {'t': 'bool', 'value': value},
  ReferenceAnyOf(:final rowIds) => {
    't': 'reference',
    'values': [for (final id in rowIds) id.value],
  },
};

FilterSpec? _decodeFilter(Object? source) {
  if (source is! Map<String, Object?>) return null;
  double? number(String key) =>
      source[key] is num ? (source[key]! as num).toDouble() : null;
  DateValue? date(String key) => source[key] is String
      ? DateValue.tryParseIso(source[key]! as String)
      : null;
  Duration? duration(String key) =>
      source[key] is int ? Duration(microseconds: source[key]! as int) : null;
  Iterable<String> strings() => source['values'] is List<Object?>
      ? (source['values']! as List<Object?>).whereType<String>()
      : const [];
  return switch (source['t']) {
    'text' when source['query'] is String => TextContains(
      source['query']! as String,
    ),
    'number' => NumberRange(min: number('min'), max: number('max')),
    'date' => DateRange(from: date('from'), to: date('to')),
    'duration' => DurationRange(min: duration('min'), max: duration('max')),
    'category' => CategoryAnyOf(strings()),
    'bool' when source['value'] is bool => BoolIs(source['value']! as bool),
    'reference' => ReferenceAnyOf(strings().map(RowId.new)),
    _ => null,
  };
}

Map<String, Object?>? _decodeMap(String? source) {
  if (source == null) return null;
  try {
    final decoded = jsonDecode(source);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}
