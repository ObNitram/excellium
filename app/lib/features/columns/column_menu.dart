import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../grid/column_type_ui.dart';
import '../views/view_providers.dart';
import '../workbook/workbook_providers.dart';
import 'column_filter_editor.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PanelTitle('Trier'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: _SortButton(
                  label: 'Croissant',
                  icon: Icons.arrow_upward,
                  selected: sortedHere && sort!.ascending,
                  onTap: () => view.toggleSort(column.id, ascending: true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SortButton(
                  label: 'Décroissant',
                  icon: Icons.arrow_downward,
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
          child: ColumnFilterEditor(column: column),
        ),
        const Divider(height: 12),
        PanelItem(
          icon: Icons.edit_outlined,
          label: 'Renommer',
          onTap: () {
            widget.close();
            renameColumn(context, ref, column);
          },
        ),
        PanelItem(
          icon: Icons.visibility_off_outlined,
          label: 'Masquer la colonne',
          onTap: () {
            view.setHidden(column.id, hidden: true);
            widget.close();
          },
        ),
        if (column.type == ColumnType.singleCategory)
          PanelItem(
            icon: Icons.view_kanban_outlined,
            label: 'Utiliser comme vue Kanban',
            onTap: () {
              view.setLayout(ViewLayout.kanban(column.id));
              widget.close();
            },
          ),
        if (column.type == ColumnType.date)
          PanelItem(
            icon: Icons.calendar_month_outlined,
            label: 'Utiliser comme vue Calendrier',
            onTap: () {
              view.setLayout(ViewLayout.calendar(column.id));
              widget.close();
            },
          ),
        const Divider(height: 12),
        PanelItem(
          icon: column.type.icon,
          label: 'Type : ${column.type.label}',
          trailing: Icon(
            _typeOpen ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: AppColors.textMuted,
          ),
          onTap: () => setState(() => _typeOpen = !_typeOpen),
        ),
        if (_typeOpen) ...[
          for (final type in ColumnType.values)
            PanelItem(
              icon: type.icon,
              label: type.label,
              selected: type == column.type,
              onTap: () async {
                await service.changeColumnType(column, type);
                // Une référence se paramètre aussitôt : on laisse le menu
                // ouvert.
                if (type != ColumnType.reference) widget.close();
              },
            ),
          if (column.type == ColumnType.reference)
            ReferenceConfigEditor(column: column),
        ],
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
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentTint : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.fieldBorder,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 12),
        const PanelTitle('Feuille liée'),
        if (others.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              'Aucune autre feuille. Ajoutez un onglet pour créer une '
              'relation.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        for (final sheet in others)
          PanelItem(
            label: sheet.name,
            selected: sheet.id == config.targetSheetId,
            onTap: () => service.configureReference(
              column,
              ReferenceConfig(
                targetSheetId: sheet.id,
                cardinality: config.cardinality,
              ),
            ),
          ),
        const PanelTitle('Relation'),
        PanelItem(
          label: '1 – n',
          selected: !many,
          onTap: () => service.configureReference(
            column,
            config.copyWith(cardinality: Cardinality.one),
          ),
        ),
        PanelItem(
          label: 'n – n',
          selected: many,
          onTap: () => service.configureReference(
            column,
            config.copyWith(cardinality: Cardinality.many),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          child: Text(
            many
                ? 'Chaque cellule peut pointer vers plusieurs lignes de la '
                      'feuille liée.'
                : 'Chaque cellule pointe vers une seule ligne de la feuille '
                      'liée.',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
