import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/row.dart';

/// Catégories proposées pour une colonne : celles définies sur la colonne,
/// dans leur ordre, puis celles seulement présentes dans les cellules, dans
/// l'ordre où on les rencontre.
List<String> categoriesOf(ColumnDef column, Iterable<SheetRow> rows) {
  final result = <String>[];
  final seen = <String>{};
  void add(String category) {
    final trimmed = category.trim();
    if (trimmed.isNotEmpty && seen.add(trimmed)) result.add(trimmed);
  }

  column.options.forEach(add);
  for (final row in rows) {
    final value = row[column.id];
    if (value is CategoryValue) value.categories.forEach(add);
  }
  return result;
}

/// Ajoute ou retire [category] d'une cellule de catégorie.
///
/// Dans une colonne à catégorie unique, choisir une autre catégorie remplace
/// la précédente, et rechoisir la même vide la cellule.
CellValue? toggleCategory(
  CellValue? current,
  String category, {
  required bool multiple,
}) {
  final existing = current is CategoryValue
      ? current.categories
      : const <String>[];
  if (!multiple) {
    return existing.length == 1 && existing.single == category
        ? null
        : CategoryValue.single(category);
  }
  final next = existing.contains(category)
      ? [
          for (final c in existing)
            if (c != category) c,
        ]
      : [...existing, category];
  return next.isEmpty ? null : CategoryValue(next);
}
