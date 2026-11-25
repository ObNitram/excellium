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
