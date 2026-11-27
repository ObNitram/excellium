import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'cell_value.dart';
import 'ids.dart';

/// Tri des lignes sur une colonne.
@immutable
final class SortSpec {
  const SortSpec(this.columnId, {this.ascending = true});

  final ColumnId columnId;
  final bool ascending;

  @override
  bool operator ==(Object other) =>
      other is SortSpec &&
      other.columnId == columnId &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(columnId, ascending);
}

/// Critère de filtre posé sur une colonne. Le critère utilisable dépend du
/// type de la colonne.
@immutable
sealed class FilterSpec {
  const FilterSpec();

  /// Un filtre inactif ne masque aucune ligne.
  bool get isActive;
}

/// Colonnes Texte : la cellule contient [query], sans tenir compte de la casse.
final class TextContains extends FilterSpec {
  const TextContains(this.query);

  final String query;

  @override
  bool get isActive => query.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is TextContains && other.query == query;

  @override
  int get hashCode => Object.hash(TextContains, query);
}

/// Colonnes Nombre et Pourcentage : valeur comprise entre [min] et [max].
final class NumberRange extends FilterSpec {
  const NumberRange({this.min, this.max});

  final double? min;
  final double? max;

  @override
  bool get isActive => min != null || max != null;

  @override
  bool operator ==(Object other) =>
      other is NumberRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(NumberRange, min, max);
}

/// Colonnes Date : date comprise entre [from] et [to], bornes incluses.
final class DateRange extends FilterSpec {
  const DateRange({this.from, this.to});

  final DateValue? from;
  final DateValue? to;

  @override
  bool get isActive => from != null || to != null;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(DateRange, from, to);
}

/// Colonnes Durée : durée comprise entre [min] et [max].
final class DurationRange extends FilterSpec {
  const DurationRange({this.min, this.max});

  final Duration? min;
  final Duration? max;

  @override
  bool get isActive => min != null || max != null;

  @override
  bool operator ==(Object other) =>
      other is DurationRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(DurationRange, min, max);
}

/// Colonnes Catégorie : la cellule contient au moins une des [categories].
final class CategoryAnyOf extends FilterSpec {
  CategoryAnyOf(Iterable<String> categories)
    : categories = Set.unmodifiable(categories);

  final Set<String> categories;

  @override
  bool get isActive => categories.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is CategoryAnyOf &&
      const SetEquality<String>().equals(other.categories, categories);

  @override
  int get hashCode =>
      Object.hash(CategoryAnyOf, const SetEquality<String>().hash(categories));
}

/// Colonnes Booléen : la cellule vaut [value]. Une cellule vide vaut faux.
final class BoolIs extends FilterSpec {
  // ignore: avoid_positional_boolean_parameters
  const BoolIs(this.value);

  final bool value;

  @override
  bool get isActive => true;

  @override
  bool operator ==(Object other) => other is BoolIs && other.value == value;

  @override
  int get hashCode => Object.hash(BoolIs, value);
}

/// Colonnes Référence : la cellule pointe vers au moins une des [rowIds].
final class ReferenceAnyOf extends FilterSpec {
  ReferenceAnyOf(Iterable<RowId> rowIds) : rowIds = Set.unmodifiable(rowIds);

  final Set<RowId> rowIds;

  @override
  bool get isActive => rowIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ReferenceAnyOf &&
      const SetEquality<RowId>().equals(other.rowIds, rowIds);

  @override
  int get hashCode =>
      Object.hash(ReferenceAnyOf, const SetEquality<RowId>().hash(rowIds));
}

/// Tri et filtres appliqués aux lignes d'une feuille.
@immutable
final class RowQuery {
  RowQuery({this.sort, Map<ColumnId, FilterSpec> filters = const {}})
    : filters = Map.unmodifiable(filters);

  static final RowQuery none = RowQuery();

  final SortSpec? sort;
  final Map<ColumnId, FilterSpec> filters;

  /// Filtres qui masquent effectivement des lignes.
  Map<ColumnId, FilterSpec> get activeFilters => {
    for (final entry in filters.entries)
      if (entry.value.isActive) entry.key: entry.value,
  };

  bool get isEmpty => sort == null && activeFilters.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is RowQuery &&
      other.sort == sort &&
      const MapEquality<ColumnId, FilterSpec>().equals(other.filters, filters);

  @override
  int get hashCode => Object.hash(
    sort,
    const MapEquality<ColumnId, FilterSpec>().hash(filters),
  );
}
