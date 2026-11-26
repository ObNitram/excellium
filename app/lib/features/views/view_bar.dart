import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/pixel_lines.dart';
import '../../shared/controls.dart';
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
    final groupColumn = ref.watch(groupColumnProvider(sheetId));
    final groupable = [
      for (final column in columns)
        if (canGroupBy(column.type)) column,
    ];
    final hasCriteria =
        !spec.query.isEmpty || hidden.isNotEmpty || groupColumn != null;
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

    return LinedBox(
      constraints: const BoxConstraints(minHeight: 40),
      // 1 point de plus en bas, pour le trait.
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
      color: AppColors.header,
      edges: const [Edges(bottom: Line(AppColors.headerLine))],
      // Comme dans la maquette : les menus et les critères à gauche, le
      // nombre de lignes et les actions poussés à droite.
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Popover(
                  anchorBuilder: (context, toggle, _) => BarButton(
                    icon: AppIcons.filter,
                    prefix: 'Vue : ',
                    label:
                        matched?.name ??
                        (full ? 'complète' : 'non enregistrée'),
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
                        const PanelNote(
                          'Aucune vue enregistrée pour cette feuille.',
                        ),
                      for (final entry in saved)
                        PanelItem(
                          label: entry.name,
                          selected: entry.id == matched?.id,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry.id == matched?.id) ...[
                                const AppIcon(
                                  AppIcons.check,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Transform.translate(
                                offset: const Offset(6, 0),
                                child: IconBtn(
                                  tooltip: 'Supprimer la vue ${entry.name}',
                                  icon: AppIcons.closeBold,
                                  iconSize: 12,
                                  size: 28,
                                  onPressed: () => ref
                                      .read(workbookServiceProvider)
                                      .deleteView(entry.id),
                                ),
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
                    icon: AppIcons.columns,
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
                        CheckRow(
                          checked: !spec.hiddenColumnIds.contains(column.id),
                          icon: column.type.icon,
                          label: columnTitle(column),
                          detail: column.type.label,
                          // On ne masque pas la dernière colonne visible.
                          onChanged: (show) {
                            if (!show && hidden.length >= columns.length - 1) {
                              return;
                            }
                            view.setHidden(column.id, hidden: !show);
                          },
                        ),
                    ],
                  ),
                ),
                if (kind == LayoutKind.grid)
                  Popover(
                    width: 260,
                    anchorBuilder: (context, toggle, _) => BarButton(
                      label: groupColumn == null
                          ? 'Regrouper'
                          : 'Regroupé par : ${columnTitle(groupColumn)}',
                      onPressed: toggle,
                    ),
                    panelBuilder: (context, close) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PanelTitle('Regrouper les lignes par'),
                        PanelItem(
                          label: 'Aucun regroupement',
                          selected: groupColumn == null,
                          onTap: () {
                            view.setGroupBy(null);
                            close();
                          },
                        ),
                        if (groupable.isEmpty)
                          const PanelNote(
                            'Aucune colonne de type Catégorie ou Référence dans '
                            'cette feuille.',
                          ),
                        for (final column in groupable)
                          PanelItem(
                            label: columnTitle(column),
                            selected: column.id == groupColumn?.id,
                            onTap: () {
                              view.setGroupBy(column.id);
                              close();
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
                            PanelNote(
                              'Aucune colonne de type « ${wanted.label} » dans '
                              'cette feuille.',
                            ),
                          for (final column in candidates)
                            PanelItem(
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
              ],
            ),
          ),
          if (spec.query.activeFilters.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              _count(
                shown.where((row) => !row.isEmpty).length,
                rows.where((row) => !row.isEmpty).length,
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
            ),
          ],
          if (!full && matched == null && !_naming) ...[
            const SizedBox(width: 8),
            BarButton(
              label: 'Enregistrer la vue',
              icon: AppIcons.bookmark,
              dropdown: false,
              accent: true,
              onPressed: () => setState(() => _naming = true),
            ),
          ],
          if (!full && matched == null && _naming) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              height: _controlHeight,
              child: TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: 'Nom de la vue',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                onSubmitted: (_) => _save(spec),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              style: _compact.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              onPressed: () => _save(spec),
              child: const Text('Enregistrer'),
            ),
            const SizedBox(width: 6),
            TextButton(
              style: _compact.copyWith(
                foregroundColor: const WidgetStatePropertyAll(
                  AppColors.textSubtle,
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onPressed: () => setState(() => _naming = false),
              child: const Text('Annuler'),
            ),
          ],
          if (hasCriteria) ...[
            const SizedBox(width: 8),
            TextButton(
              style: _compact,
              onPressed: view.clearCriteria,
              child: const Text('Tout effacer'),
            ),
          ],
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
      TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
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

  static AppIconData _layoutIcon(LayoutKind kind) => switch (kind) {
    LayoutKind.grid => AppIcons.grid,
    LayoutKind.kanban => AppIcons.kanban,
    LayoutKind.calendar => AppIcons.calendar,
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
      height: AppSizes.smallControl,
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.fieldBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 2),
          IconBtn(
            tooltip: 'Retirer : $label',
            icon: AppIcons.closeBold,
            iconSize: 12,
            size: 22,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
