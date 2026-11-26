import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'ids.dart';
import 'query.dart';

/// Les façons d'afficher une feuille.
enum LayoutKind { grid, kanban, calendar }

/// Affichage d'une vue.
///
/// [keyColumnId] désigne la colonne des étapes pour un kanban et la colonne
/// de date pour un calendrier. `null` laisse l'application choisir la
/// première colonne qui convient.
@immutable
final class ViewLayout {
  const ViewLayout.grid() : kind = LayoutKind.grid, keyColumnId = null;

  const ViewLayout.kanban([this.keyColumnId]) : kind = LayoutKind.kanban;

  const ViewLayout.calendar([this.keyColumnId]) : kind = LayoutKind.calendar;

  const ViewLayout(this.kind, [this.keyColumnId]);

  final LayoutKind kind;
  final ColumnId? keyColumnId;

  @override
  bool operator ==(Object other) =>
      other is ViewLayout &&
      other.kind == kind &&
      other.keyColumnId == keyColumnId;

  @override
  int get hashCode => Object.hash(kind, keyColumnId);
}

/// Ce qui définit une vue : affichage, tri, filtres et colonnes masquées.
@immutable
final class ViewSpec {
  ViewSpec({
    this.layout = const ViewLayout.grid(),
    RowQuery? query,
    Iterable<ColumnId> hiddenColumnIds = const [],
  }) : query = query ?? RowQuery.none,
       hiddenColumnIds = Set.unmodifiable(hiddenColumnIds);

  /// La vue complète : grille, sans tri, sans filtre, toutes colonnes visibles.
  static final ViewSpec full = ViewSpec();

  final ViewLayout layout;
  final RowQuery query;
  final Set<ColumnId> hiddenColumnIds;

  bool get isFull =>
      layout.kind == LayoutKind.grid &&
      query.isEmpty &&
      hiddenColumnIds.isEmpty;

  ViewSpec copyWith({
    ViewLayout? layout,
    RowQuery? query,
    Iterable<ColumnId>? hiddenColumnIds,
  }) => ViewSpec(
    layout: layout ?? this.layout,
    query: query ?? this.query,
    hiddenColumnIds: hiddenColumnIds ?? this.hiddenColumnIds,
  );

  /// La même vue sans aucune mention de [columnId] : ni tri, ni filtre, ni
  /// masquage, ni clé d'affichage. Sert quand la colonne est supprimée.
  ViewSpec withoutColumn(ColumnId columnId) => ViewSpec(
    layout: layout.keyColumnId == columnId ? ViewLayout(layout.kind) : layout,
    query: RowQuery(
      sort: query.sort?.columnId == columnId ? null : query.sort,
      filters: {
        for (final entry in query.filters.entries)
          if (entry.key != columnId) entry.key: entry.value,
      },
    ),
    hiddenColumnIds: hiddenColumnIds.where((id) => id != columnId),
  );

  /// Forme comparable : deux vues qui affichent la même chose sont égales,
  /// même si l'une garde un filtre vide.
  ViewSpec get normalized => ViewSpec(
    layout: layout,
    query: RowQuery(sort: query.sort, filters: query.activeFilters),
    hiddenColumnIds: hiddenColumnIds,
  );

  @override
  bool operator ==(Object other) =>
      other is ViewSpec &&
      other.layout == layout &&
      other.query == query &&
      const SetEquality<ColumnId>().equals(
        other.hiddenColumnIds,
        hiddenColumnIds,
      );

  @override
  int get hashCode => Object.hash(
    layout,
    query,
    const SetEquality<ColumnId>().hash(hiddenColumnIds),
  );
}

/// Une vue enregistrée d'une feuille.
@immutable
final class SavedView {
  const SavedView({
    required this.id,
    required this.sheetId,
    required this.name,
    required this.position,
    required this.spec,
  });

  final ViewId id;
  final SheetId sheetId;
  final String name;
  final int position;
  final ViewSpec spec;

  SavedView copyWith({String? name, int? position, ViewSpec? spec}) =>
      SavedView(
        id: id,
        sheetId: sheetId,
        name: name ?? this.name,
        position: position ?? this.position,
        spec: spec ?? this.spec,
      );

  @override
  bool operator ==(Object other) =>
      other is SavedView &&
      other.id == id &&
      other.sheetId == sheetId &&
      other.name == name &&
      other.position == position &&
      other.spec == spec;

  @override
  int get hashCode => Object.hash(id, sheetId, name, position, spec);
}
