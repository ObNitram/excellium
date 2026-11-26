import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../grid/cell_format.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import 'view_providers.dart';

/// Barre de vue : vue enregistrée, affichage, colonnes, critères actifs.
class ViewBar extends ConsumerStatefulWidget {
  const ViewBar({super.key, required this.sheet});

  final Sheet sheet;

  @override
  ConsumerState<ViewBar> createState() => _ViewBarState();
}

class _ViewBarState extends ConsumerState<ViewBar> {
  final _nameController = TextEditingController();
  bool _naming = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(ViewSpec spec) async {
    await ref
        .read(workbookServiceProvider)
        .saveView(widget.sheet.id, spec, name: _nameController.text);
    if (!mounted) return;
    _nameController.clear();
    setState(() => _naming = false);
  }

  @override
  Widget build(BuildContext context) {
    final sheetId = widget.sheet.id;
    final spec = ref.watch(viewSpecProvider(sheetId));
    final view = ref.read(viewSpecProvider(sheetId).notifier);
    final matched = ref.watch(matchedViewProvider(sheetId));
    final saved = ref.watch(savedViewsProvider(sheetId)).value ?? const [];
    final columns = ref.watch(columnsProvider(sheetId)).value ?? const [];
    final rows = ref.watch(rowsProvider(sheetId)).value ?? const [];
    final shown = ref.watch(visibleRowsProvider(sheetId));
    final keyColumn = ref.watch(layoutKeyColumnProvider(sheetId));
    final byId = {for (final column in columns) column.id: column};
    final full = spec.normalized.isFull;
    final hidden = [
      for (final column in columns)
        if (spec.hiddenColumnIds.contains(column.id)) column,
    ];
    final hasCriteria = !spec.query.isEmpty || hidden.isNotEmpty;
    final kind = spec.layout.kind;

    final items = <(String, VoidCallback)>[
      if (spec.query.sort case final sort?)
        if (byId[sort.columnId] case final column?)
          (
            'Trié par ${column.label}, '
                '${sort.ascending ? 'croissant' : 'décroissant'}',
            view.clearSort,
          ),
      for (final entry in spec.query.activeFilters.entries)
        if (byId[entry.key] case final column?)
          (
            _describe(ref, column, entry.value),
            () => view.setFilter(column.id, null),
          ),
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.header,
        border: Border(bottom: BorderSide(color: AppColors.headerLine)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Popover(
            anchorBuilder: (context, toggle, _) => BarButton(
              icon: Icons.filter_alt_outlined,
              label:
                  'Vue : ${matched?.name ?? (full ? 'complète' : 'non enregistrée')}',
              strong: true,
              onPressed: toggle,
            ),
            panelBuilder: (context, close) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const PanelTitle('Vues de la feuille'),
                PanelItem(
                  label: 'Vue complète',
                  selected: full,
                  onTap: () {
                    view.reset();
                    close();
                  },
                ),
                if (saved.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Aucune vue enregistrée pour cette feuille.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                for (final entry in saved)
                  PanelItem(
                    label: entry.name,
                    selected: entry.id == matched?.id,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.id == matched?.id)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        IconButton(
                          tooltip: 'Supprimer la vue ${entry.name}',
                          iconSize: 14,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close),
                          onPressed: () => ref
                              .read(storeProvider)
                              .views
                              .deleteView(entry.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      view.apply(entry.spec);
                      close();
                    },
                  ),
              ],
            ),
          ),
          Popover(
            width: 220,
            anchorBuilder: (context, toggle, _) => BarButton(
              icon: _layoutIcon(kind),
              label: 'Affichage : ${_layoutLabel(kind)}',
              onPressed: toggle,
            ),
            panelBuilder: (context, close) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const PanelTitle('Type d\'affichage'),
                for (final option in LayoutKind.values)
                  PanelItem(
                    icon: _layoutIcon(option),
                    label: _layoutLabel(option),
                    selected: option == kind,
                    onTap: () {
                      view.setLayout(ViewLayout(option));
                      close();
                    },
                  ),
              ],
            ),
          ),
          Popover(
            anchorBuilder: (context, toggle, _) => BarButton(
              icon: Icons.view_column_outlined,
              label: hidden.isEmpty
                  ? 'Colonnes'
                  : 'Colonnes : ${hidden.length} '
                        '${hidden.length > 1 ? 'masquées' : 'masquée'}',
              onPressed: toggle,
            ),
            panelBuilder: (context, close) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PanelTitle(
                  'Colonnes affichées',
                  trailing: PanelAction(
                    label: 'Tout afficher',
                    onPressed: view.showAllColumns,
                  ),
                ),
                for (final column in columns)
                  _ColumnCheck(
                    column: column,
                    shown: !spec.hiddenColumnIds.contains(column.id),
                    // On ne masque pas la dernière colonne visible.
                    onChanged: (show) {
                      if (!show && hidden.length >= columns.length - 1) return;
                      view.setHidden(column.id, hidden: !show);
                    },
                  ),
              ],
            ),
          ),
          if (kind != LayoutKind.grid)
            Popover(
              width: 260,
              anchorBuilder: (context, toggle, _) => BarButton(
                label:
                    '${kind == LayoutKind.kanban ? 'Étapes' : 'Date'} : '
                    '${keyColumn == null ? 'aucune colonne' : columnTitle(keyColumn)}',
                onPressed: toggle,
              ),
              panelBuilder: (context, close) {
                final wanted = kind == LayoutKind.kanban
                    ? ColumnType.singleCategory
                    : ColumnType.date;
                final candidates = [
                  for (final column in columns)
                    if (column.type == wanted) column,
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PanelTitle(
                      kind == LayoutKind.kanban
                          ? 'Colonne des étapes'
                          : 'Colonne de date',
                    ),
                    if (candidates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Aucune colonne de type « ${wanted.label} » dans '
                          'cette feuille.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    for (final column in candidates)
                      PanelItem(
                        icon: column.type.icon,
                        label: columnTitle(column),
                        selected: column.id == keyColumn?.id,
                        onTap: () {
                          view.setLayout(ViewLayout(kind, column.id));
                          close();
                        },
                      ),
                  ],
                );
              },
            ),
          for (final (label, remove) in items)
            _Criterion(label: label, onRemove: remove),
          if (spec.query.activeFilters.isNotEmpty)
            Text(
              _count(
                shown.where((row) => !row.isEmpty).length,
                rows.where((row) => !row.isEmpty).length,
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
            ),
          if (!full && matched == null && !_naming)
            BarButton(
              label: 'Enregistrer la vue',
              icon: Icons.bookmark_add_outlined,
              dropdown: false,
              onPressed: () => setState(() => _naming = true),
            ),
          if (!full && matched == null && _naming) ...[
            SizedBox(
              width: 180,
              child: TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  hintText: 'Nom de la vue',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(),
                  constraints: BoxConstraints.tightFor(height: _controlHeight),
                  contentPadding: EdgeInsets.fromLTRB(8, 5, 8, 5),
                ),
                onSubmitted: (_) => _save(spec),
              ),
            ),
            FilledButton(
              style: _compact,
              onPressed: () => _save(spec),
              child: const Text('Enregistrer'),
            ),
            TextButton(
              style: _compact,
              onPressed: () => setState(() => _naming = false),
              child: const Text('Annuler'),
            ),
          ],
          if (hasCriteria)
            TextButton(
              style: _compact,
              onPressed: view.clearCriteria,
              child: const Text('Tout effacer'),
            ),
        ],
      ),
    );
  }

  /// Tous les éléments de la barre ont la même hauteur : la barre ne change
  /// pas de taille (et la grille ne saute pas) quand un critère apparaît.
  static const double _controlHeight = 28;

  static final ButtonStyle _compact = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, _controlHeight)),
    maximumSize: const WidgetStatePropertyAll(
      Size(double.infinity, _controlHeight),
    ),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );

  static String _count(int shown, int total) =>
      '$shown ${shown > 1 ? 'lignes affichées' : 'ligne affichée'} sur $total';

  static String _layoutLabel(LayoutKind kind) => switch (kind) {
    LayoutKind.grid => 'Grille',
    LayoutKind.kanban => 'Kanban',
    LayoutKind.calendar => 'Calendrier',
  };

  static IconData _layoutIcon(LayoutKind kind) => switch (kind) {
    LayoutKind.grid => Icons.grid_on,
    LayoutKind.kanban => Icons.view_kanban_outlined,
    LayoutKind.calendar => Icons.calendar_month_outlined,
  };

  /// Écrit un filtre en clair, par exemple « Statut est En cours ou À faire ».
  static String _describe(WidgetRef ref, ColumnDef column, FilterSpec filter) {
    final name = column.label;
    String range(String? min, String? max) {
      if (min != null && max != null) return '$name entre $min et $max';
      return min != null ? '$name ≥ $min' : '$name ≤ $max';
    }

    switch (filter) {
      case TextContains(:final query):
        return '$name contient « ${query.trim()} »';
      case NumberRange(:final min, :final max):
        String? show(double? v) =>
            v == null ? null : formatCell(NumberValue(v), column.type);
        return range(show(min), show(max));
      case DateRange(:final from, :final to):
        String? show(DateValue? v) =>
            v == null ? null : formatCell(v, ColumnType.date);
        return range(show(from), show(to));
      case DurationRange(:final min, :final max):
        String? show(Duration? v) => v == null
            ? null
            : formatCell(DurationValue(v), ColumnType.duration);
        return range(show(min), show(max));
      case CategoryAnyOf(:final categories):
        return '$name est ${categories.join(' ou ')}';
      case BoolIs(:final value):
        return '$name est ${value ? 'Vrai' : 'Faux'}';
      case ReferenceAnyOf(:final rowIds):
        final target = column.reference?.targetSheetId;
        final labels = target == null
            ? const <RowId, String>{}
            : ref.watch(rowLabelsProvider(target));
        return '$name est '
            '${rowIds.map((id) => labels[id] ?? 'Ligne supprimée').join(' ou ')}';
    }
  }
}

class _Criterion extends StatelessWidget {
  const _Criterion({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.fieldBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          IconButton(
            tooltip: 'Retirer : $label',
            iconSize: 12,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ColumnCheck extends StatelessWidget {
  const _ColumnCheck({
    required this.column,
    required this.shown,
    required this.onChanged,
  });

  final ColumnDef column;
  final bool shown;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!shown),
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Checkbox(
              value: shown,
              activeColor: AppColors.accent,
              onChanged: (next) => onChanged(next ?? false),
            ),
            Icon(column.type.icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                columnTitle(column),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                column.type.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
