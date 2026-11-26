import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/popover.dart';
import '../../shared/segmented.dart';
import '../../shared/providers.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';
import '../workbook/workbook_providers.dart';
import 'column_filter_editor.dart';
import 'delete_column.dart';
import 'rename_column.dart';

/// Menu d'une colonne : tri, filtre, masquage, affichages, renommage, type et
/// paramètres de relation.
class ColumnMenu extends ConsumerStatefulWidget {
  const ColumnMenu({
    super.key,
    required this.column,
    required this.close,
    this.typeOpen = false,
  });

  final ColumnDef column;
  final VoidCallback close;

  /// Ouvre le menu avec la section du type déjà dépliée.
  final bool typeOpen;

  @override
  ConsumerState<ColumnMenu> createState() => _ColumnMenuState();
}

class _ColumnMenuState extends ConsumerState<ColumnMenu> {
  late bool _typeOpen = widget.typeOpen;
  int _filterReset = 0;

  @override
  Widget build(BuildContext context) {
    final column = widget.column;
    final sheetId = column.sheetId;
    final spec = ref.watch(viewSpecProvider(sheetId));
    final view = ref.read(viewSpecProvider(sheetId).notifier);
    final service = ref.read(workbookServiceProvider);
    final sort = spec.query.sort;
    final sortedHere = sort?.columnId == column.id;
    final filterOn = spec.query.activeFilters.containsKey(column.id);
    final columnCount = ref.watch(columnsProvider(sheetId)).value?.length ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PanelTitle('Trier'),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: _SortButton(
                  label: 'Croissant',
                  icon: AppIcons.sortAscending,
                  selected: sortedHere && sort!.ascending,
                  onTap: () => view.toggleSort(column.id, ascending: true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SortButton(
                  label: 'Décroissant',
                  icon: AppIcons.sortDescending,
                  selected: sortedHere && !sort!.ascending,
                  onTap: () => view.toggleSort(column.id, ascending: false),
                ),
              ),
            ],
          ),
        ),
        PanelTitle(
          'Filtrer',
          trailing: filterOn
              ? PanelAction(
                  label: 'Effacer',
                  onPressed: () {
                    view.setFilter(column.id, null);
                    setState(() => _filterReset++);
                  },
                )
              : null,
        ),
        // « Effacer » change la clé pour vider les champs. La clé ne dépend
        // pas de l'état du filtre : sinon le champ serait recréé, et perdrait
        // le focus, dès le premier caractère saisi.
        KeyedSubtree(
          key: ValueKey('filter-${column.id.value}-$_filterReset'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: ColumnFilterEditor(column: column),
          ),
        ),
        const PanelDivider(),
        _Action(
          icon: AppIcons.rename,
          label: 'Renommer',
          onTap: () {
            widget.close();
            renameColumn(context, ref, column);
          },
        ),
        _Action(
          icon: AppIcons.hide,
          label: 'Masquer la colonne',
          onTap: () {
            view.setHidden(column.id, hidden: true);
            widget.close();
          },
        ),
        if (canGroupBy(column.type))
          spec.groupBy == column.id
              ? _Action(
                  icon: AppIcons.group,
                  label: 'Ne plus regrouper',
                  on: true,
                  onTap: () {
                    view.setGroupBy(null);
                    widget.close();
                  },
                )
              : _Action(
                  icon: AppIcons.group,
                  label: 'Regrouper par cette colonne',
                  onTap: () {
                    view.setGroupBy(column.id);
                    widget.close();
                  },
                ),
        if (column.type == ColumnType.singleCategory)
          _Action(
            icon: AppIcons.kanban,
            label: 'Utiliser comme vue Kanban',
            onTap: () {
              view.setLayout(ViewLayout.kanban(column.id));
              widget.close();
            },
          ),
        if (column.type == ColumnType.date)
          _Action(
            icon: AppIcons.calendar,
            label: 'Utiliser comme vue Calendrier',
            onTap: () {
              view.setLayout(ViewLayout.calendar(column.id));
              widget.close();
            },
          ),
        const PanelDivider(),
        _Action(
          icon: column.type.icon,
          labelPrefix: 'Type : ',
          label: column.type.label,
          trailing: AppIcon(
            AppIcons.chevronDown,
            size: 10,
            color: AppColors.text,
            turns: _typeOpen ? 2 : 0,
          ),
          onTap: () => setState(() => _typeOpen = !_typeOpen),
        ),
        if (_typeOpen) ...[
          for (final type in ColumnType.values)
            PanelItem(
              icon: type.icon,
              label: type.label,
              selected: type == column.type,
              trailing: type == column.type
                  ? null
                  : Text(
                      type.hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
              onTap: () async {
                final selection = ref.read(selectionProvider.notifier);
                await service.changeColumnType(column, type);
                // Une formule se saisit dans la barre d'édition : la colonne
                // est sélectionnée pour l'écrire tout de suite.
                if (type == ColumnType.formula) {
                  selection.selectColumn(column.id);
                }
                // Une référence se paramètre aussitôt : on laisse le menu
                // ouvert.
                if (type != ColumnType.reference) widget.close();
              },
            ),
          if (column.type == ColumnType.reference)
            ReferenceConfigEditor(column: column),
        ],
        const PanelDivider(),
        _Action(
          icon: AppIcons.delete,
          label: 'Supprimer la colonne',
          danger: true,
          // Il reste toujours au moins une colonne dans la feuille.
          onTap: columnCount > 1
              ? () {
                  widget.close();
                  deleteColumn(context, column);
                }
              : null,
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      child: _Bordered(
        selected: selected,
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feuille liée et cardinalité d'une colonne Référence.
class ReferenceConfigEditor extends ConsumerWidget {
  const ReferenceConfigEditor({super.key, required this.column});

  final ColumnDef column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = column.reference ?? const ReferenceConfig();
    final sheets = ref.watch(sheetsProvider).value ?? const [];
    final others = [
      for (final sheet in sheets)
        if (sheet.id != column.sheetId) sheet,
    ];
    final service = ref.read(workbookServiceProvider);
    final many = config.cardinality == Cardinality.many;

    const label = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSubtle,
    );
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Feuille liée', style: label),
          const SizedBox(height: 6),
          if (others.isEmpty)
            const Text(
              'Aucune autre feuille. Ajoutez un onglet pour créer une '
              'relation.',
              style: AppText.help,
            ),
          for (final (index, sheet) in others.indexed) ...[
            if (index > 0) const SizedBox(height: 6),
            _SheetChoice(
              name: sheet.name,
              selected: sheet.id == config.targetSheetId,
              onTap: () => service.configureReference(
                column,
                ReferenceConfig(
                  targetSheetId: sheet.id,
                  cardinality: config.cardinality,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Relation', style: label),
          const SizedBox(height: 6),
          Segmented<Cardinality>(
            expanded: true,
            selected: config.cardinality,
            onSelected: (value) => service.configureReference(
              column,
              config.copyWith(cardinality: value),
            ),
            options: const [
              (value: Cardinality.one, label: '1 – n', icon: null),
              (value: Cardinality.many, label: 'n – n', icon: null),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            many
                ? 'Chaque cellule peut pointer vers plusieurs lignes de la '
                      'feuille liée.'
                : 'Chaque cellule pointe vers une seule ligne de la feuille '
                      'liée.',
            style: AppText.help,
          ),
        ],
      ),
    );
  }
}

/// Action du menu de colonne : 38 px, d'un bord à l'autre du panneau.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelPrefix,
    this.trailing,
    this.on = false,
    this.danger = false,
  });

  final AppIconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? labelPrefix;
  final Widget? trailing;

  /// Action active (« Ne plus regrouper ») : en couleur d'accent, sans fond.
  final bool on;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.textMuted
        : danger
        ? AppColors.danger
        : (on ? AppColors.accent : AppColors.text);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: on,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              AppIcon(icon, color: on || danger ? color : AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (labelPrefix != null)
                        TextSpan(
                          text: labelPrefix,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      TextSpan(text: label),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton à bordure de 6 px d'arrondi ; choisi, il prend la couleur
/// d'accent.
class _Bordered extends StatelessWidget {
  const _Bordered({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentTint : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.fieldBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }
}

/// Une feuille proposée comme cible d'une référence.
class _SheetChoice extends StatelessWidget {
  const _SheetChoice({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      child: _Bordered(
        selected: selected,
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) AppIcon(AppIcons.check, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
