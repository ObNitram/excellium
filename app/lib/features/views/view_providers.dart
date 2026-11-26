import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';
import '../grid/grid_providers.dart';

/// La vue en cours sur une feuille : affichage, tri, filtres et colonnes
/// masquées. Elle vit en mémoire ; l'utilisateur peut l'enregistrer.
final viewSpecProvider =
    NotifierProvider.family<ViewSpecNotifier, ViewSpec, SheetId>(
      ViewSpecNotifier.new,
    );

class ViewSpecNotifier extends Notifier<ViewSpec> {
  ViewSpecNotifier(this.sheetId);

  final SheetId sheetId;

  @override
  ViewSpec build() => ViewSpec.full;

  void apply(ViewSpec spec) => state = spec;

  void reset() => state = ViewSpec.full;

  /// Retire le tri, les filtres et réaffiche les colonnes, sans changer
  /// d'affichage.
  void clearCriteria() => state = ViewSpec(layout: state.layout);

  void setLayout(ViewLayout layout) => state = state.copyWith(layout: layout);

  /// Trie sur [columnId] ; redemander le même tri le retire.
  void toggleSort(ColumnId columnId, {required bool ascending}) {
    final same = state.query.sort == SortSpec(columnId, ascending: ascending);
    state = state.copyWith(
      query: RowQuery(
        sort: same ? null : SortSpec(columnId, ascending: ascending),
        filters: state.query.filters,
      ),
    );
  }

  void clearSort() =>
      state = state.copyWith(query: RowQuery(filters: state.query.filters));

  /// Pose un filtre sur une colonne ; `null` le retire.
  void setFilter(ColumnId columnId, FilterSpec? filter) {
    final filters = Map<ColumnId, FilterSpec>.of(state.query.filters);
    if (filter == null) {
      filters.remove(columnId);
    } else {
      filters[columnId] = filter;
    }
    state = state.copyWith(
      query: RowQuery(sort: state.query.sort, filters: filters),
    );
  }

  void setHidden(ColumnId columnId, {required bool hidden}) {
    final ids = Set<ColumnId>.of(state.hiddenColumnIds);
    if (hidden) {
      ids.add(columnId);
    } else {
      ids.remove(columnId);
    }
    state = state.copyWith(hiddenColumnIds: ids);
  }

  void showAllColumns() => state = state.copyWith(hiddenColumnIds: const []);
}

/// Les vues enregistrées d'une feuille.
final savedViewsProvider = StreamProvider.family<List<SavedView>, SheetId>(
  (ref, sheetId) => ref.watch(storeProvider).views.watchViews(sheetId),
);

/// La vue enregistrée qui correspond à la vue en cours, s'il y en a une.
final matchedViewProvider = Provider.family<SavedView?, SheetId>((
  ref,
  sheetId,
) {
  final current = ref.watch(viewSpecProvider(sheetId)).normalized;
  final saved = ref.watch(savedViewsProvider(sheetId)).value ?? const [];
  for (final view in saved) {
    if (view.spec.normalized == current) return view;
  }
  return null;
});

/// Les colonnes affichées : toutes sauf celles masquées par la vue. Il reste
/// toujours au moins une colonne.
final visibleColumnsProvider = Provider.family<List<ColumnDef>, SheetId>((
  ref,
  sheetId,
) {
  final columns = ref.watch(columnsProvider(sheetId)).value ?? const [];
  final hidden = ref.watch(
    viewSpecProvider(sheetId).select((spec) => spec.hiddenColumnIds),
  );
  final visible = [
    for (final column in columns)
      if (!hidden.contains(column.id)) column,
  ];
  return visible.isEmpty && columns.isNotEmpty ? [columns.first] : visible;
});

/// Les lignes affichées, filtrées et triées par la vue.
final visibleRowsProvider = Provider.family<List<SheetRow>, SheetId>((
  ref,
  sheetId,
) {
  final columns = ref.watch(columnsProvider(sheetId)).value ?? const [];
  final rows = ref.watch(rowsProvider(sheetId)).value ?? const [];
  final query = ref.watch(
    viewSpecProvider(sheetId).select((spec) => spec.query),
  );
  if (query.isEmpty) return rows;

  // Un tri sur une colonne Référence se fait sur les libellés affichés.
  ReferenceLabel? label;
  final sortId = query.sort?.columnId;
  for (final column in columns) {
    final target = column.reference?.targetSheetId;
    if (column.id == sortId && target != null) {
      final labels = ref.watch(rowLabelsProvider(target));
      label = (id) => labels[id] ?? '';
    }
  }
  return applyRowQuery(rows, columns, query, referenceLabel: label);
});

/// La colonne qui sert de clé à l'affichage en cours : étapes d'un kanban ou
/// date d'un calendrier. À défaut de choix valide, la première colonne du bon
/// type.
final layoutKeyColumnProvider = Provider.family<ColumnDef?, SheetId>((
  ref,
  sheetId,
) {
  final layout = ref.watch(
    viewSpecProvider(sheetId).select((spec) => spec.layout),
  );
  final wanted = switch (layout.kind) {
    LayoutKind.grid => null,
    LayoutKind.kanban => ColumnType.singleCategory,
    LayoutKind.calendar => ColumnType.date,
  };
  if (wanted == null) return null;
  final columns = ref.watch(columnsProvider(sheetId)).value ?? const [];
  final candidates = [
    for (final column in columns)
      if (column.type == wanted) column,
  ];
  for (final column in candidates) {
    if (column.id == layout.keyColumnId) return column;
  }
  return candidates.isEmpty ? null : candidates.first;
});
