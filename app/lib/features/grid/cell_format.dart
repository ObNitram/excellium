import 'package:excellium_core/excellium_core.dart';

/// Texte affiché dans la grille pour une valeur de cellule.
///
/// C'est de la présentation : la valeur stockée ne change pas. Un nombre
/// peut avoir un nombre fixe de [decimals] et le symbole € ([currency]).
String formatCell(
  CellValue? value,
  ColumnType type, {
  int? decimals,
  bool currency = false,
}) => switch (value) {
  null => '',
  TextValue(:final text) => text,
  NumberValue(:final number) => formatAmount(
    number,
    percent: type == ColumnType.percent,
    decimals: decimals,
    currency: currency,
  ),
  DateValue() => cellInputText(value),
  DurationValue(:final duration) => _formatDuration(duration),
  CategoryValue(:final categories) => categories.join(', '),
  BoolValue(:final value) => value ? 'Vrai' : 'Faux',
  ReferenceValue(:final rowIds) =>
    rowIds.length == 1 ? '1 référence' : '${rowIds.length} références',
};

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours h ${minutes.toString().padLeft(2, '0')}';
}

/// Un nombre tel qu'affiché : milliers séparés, [decimals] décimales
/// (sinon sans zéros inutiles), suivi de « % » ou de « € ».
String formatAmount(
  double number, {
  bool percent = false,
  int? decimals,
  bool currency = false,
}) {
  final text = _groupThousands(number, decimals);
  if (percent) return '$text %';
  if (currency) return '$text €';
  return text;
}

/// « 1234567,5 » devient « 1 234 567,5 ».
String _groupThousands(double number, [int? places]) {
  final plain = places == null
      ? formatNumber(number.abs())
      : number.abs().toStringAsFixed(places).replaceAll('.', ',');
  final parts = plain.split(',');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final sign = number < 0 ? '-' : '';
  final decimals = parts.length > 1 ? ',${parts[1]}' : '';
  return '$sign$buffer$decimals';
}
