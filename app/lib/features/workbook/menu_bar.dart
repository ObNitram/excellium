import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../columns/delete_column.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../grid/sheet_grid.dart' show deleteRow;
import '../views/view_providers.dart';
import 'sheet_actions.dart';
import 'workbook_providers.dart';

/// Menus de la barre de titre : Fichier, Édition, Affichage, Insertion,
/// Format et Données. Ils regroupent les actions déjà offertes ailleurs
/// (barres, menus de colonne, onglets) et leurs raccourcis clavier.
class WorkbookMenuBar extends StatelessWidget {
  const WorkbookMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        _Menu(label: 'Fichier', entries: _file),
        _Menu(label: 'Édition', entries: _edit),
        _Menu(label: 'Affichage', entries: _display),
        _Menu(label: 'Insertion', entries: _insert),
        _Menu(label: 'Format', entries: _format),
        _Menu(label: 'Données', entries: _data),
      ],
    );
  }
}

/// Construit les entrées d'un menu. [watch] suit l'état pour mettre les
/// entrées à jour ; [act] et [screen] restent valables après la fermeture du
/// menu, pour les actions qui attendent (une confirmation, une création).
typedef _MenuBuilder = List<Widget> Function(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
);

class _Menu extends ConsumerWidget {
  const _Menu({required this.label, required this.entries});

  final String label;
  final _MenuBuilder entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Popover(
      width: 280,
      anchorBuilder: (context, toggle, isOpen) => Semantics(
        button: true,
        child: Material(
          color: isOpen ? AppColors.hover : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: AppSizes.control,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
          ),
        ),
      ),
      // Le panneau est reconstruit à chaque ouverture : les entrées suivent
      // la sélection et l'état du classeur.
      panelBuilder: (panelContext, close) => Consumer(
        builder: (_, watch, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: entries(context, watch, ref, close),
        ),
      ),
    );
  }
}

/// Entrée de menu avec son raccourci clavier à droite.
Widget _item({
  required String label,
  required VoidCallback? onTap,
  required VoidCallback close,
  AppIconData? icon,
  String? shortcut,
  bool checked = false,
  bool danger = false,
}) => PanelItem(
  label: label,
  icon: icon,
  danger: danger,
  selected: checked,
  onTap: onTap == null
      ? null
      : () {
          close();
          onTap();
        },
  trailing: shortcut == null
      ? null
      : Text(
          shortcut,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
);

const _divider = Padding(
  padding: EdgeInsets.symmetric(vertical: 4),
  child: PanelDivider(),
);

// ---------------------------------------------------------------- Fichier

List<Widget> _file(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
) {
  final sheet = watch.watch(activeSheetProvider);
  final sheets = watch.watch(sheetsProvider).value ?? const <Sheet>[];
  return [
    _item(
      label: 'Nouvelle feuille',
      icon: AppIcons.plus,
      close: close,
      onTap: () => _newSheet(act),
    ),
    _divider,
    _item(
      label: 'Renommer la feuille',
      icon: AppIcons.rename,
      close: close,
      onTap: sheet == null ? null : () => renameSheet(screen, act, sheet),
    ),
    _item(
      label: 'Supprimer la feuille',
      icon: AppIcons.delete,
      danger: true,
      close: close,
      onTap: sheet == null || sheets.length < 2
          ? null
          : () => deleteSheet(screen, act, sheet),
    ),
  ];
}

Future<void> _newSheet(WidgetRef ref) async {
  final created = await ref.read(workbookServiceProvider).createSheet();
  ref.read(chosenSheetIdProvider.notifier).choose(created.id);
}

// ---------------------------------------------------------------- Édition

List<Widget> _edit(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
) {
  final service = act.read(workbookServiceProvider);
  final undo =
      watch.watch(undoStateProvider).value ?? (canUndo: false, canRedo: false);
  final cell = watch.watch(selectedCellProvider);
  final column = watch.watch(selectedColumnProvider);
  final columns = column == null
      ? const <ColumnDef>[]
      : watch.watch(columnsProvider(column.sheetId)).value ?? const [];
  return [
    _item(
      label: 'Annuler',
      icon: AppIcons.undo,
      shortcut: 'Ctrl+Z',
      close: close,
      onTap: undo.canUndo ? service.undo : null,
    ),
    _item(
      label: 'Rétablir',
      icon: AppIcons.redo,
      shortcut: 'Ctrl+Y',
      close: close,
      onTap: undo.canRedo ? service.redo : null,
    ),
    _divider,
    _item(
      label: 'Vider la cellule',
      icon: AppIcons.close,
      close: close,
      onTap: cell == null || cell.column.type == ColumnType.formula
          ? null
          : () => service.setValue(cell.row, cell.column, null),
    ),
    _item(
      label: cell == null
          ? 'Supprimer la ligne'
          : 'Supprimer la ligne ${cell.row.position + 1}',
      icon: AppIcons.delete,
      danger: true,
      close: close,
      onTap: cell == null ? null : () => deleteRow(screen, act, cell.row),
    ),
    _item(
      label: column == null
          ? 'Supprimer la colonne'
          : 'Supprimer la colonne ${column.label}',
      icon: AppIcons.delete,
      danger: true,
      close: close,
      onTap: column == null || columns.length < 2
          ? null
          : () => deleteColumn(screen, column),
    ),
  ];
}

// -------------------------------------------------------------- Affichage

List<Widget> _display(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
) {
  final sheet = watch.watch(activeSheetProvider);
  final zoom = act.read(zoomProvider.notifier);
  final pane = watch.watch(calcPaneProvider);
  final kind = sheet == null
      ? LayoutKind.grid
      : watch.watch(viewSpecProvider(sheet.id)).layout.kind;
  void layout(LayoutKind next) {
    if (sheet == null) return;
    act.read(viewSpecProvider(sheet.id).notifier).setLayout(ViewLayout(next));
  }

  return [
    _item(
      label: 'Grille',
      icon: AppIcons.grid,
      checked: kind == LayoutKind.grid,
      close: close,
      onTap: () => layout(LayoutKind.grid),
    ),
    _item(
      label: 'Kanban',
      icon: AppIcons.kanban,
      checked: kind == LayoutKind.kanban,
      close: close,
      onTap: () => layout(LayoutKind.kanban),
    ),
    _item(
      label: 'Calendrier',
      icon: AppIcons.calendar,
      checked: kind == LayoutKind.calendar,
      close: close,
      onTap: () => layout(LayoutKind.calendar),
    ),
    _divider,
    _item(
      label: 'Zoom avant',
      shortcut: 'Ctrl++',
      close: close,
      onTap: zoom.zoomIn,
    ),
    _item(
      label: 'Zoom arrière',
      shortcut: 'Ctrl+-',
      close: close,
      onTap: zoom.zoomOut,
    ),
    _item(
      label: 'Taille réelle',
      shortcut: 'Ctrl+0',
      close: close,
      onTap: zoom.reset,
    ),
    _divider,
    _item(
      label: 'Cases de calcul',
      checked: !pane.hidden,
      close: close,
      onTap: act.read(calcPaneProvider.notifier).toggle,
    ),
  ];
}

// -------------------------------------------------------------- Insertion

List<Widget> _insert(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
) {
  final sheet = watch.watch(activeSheetProvider);
  final service = act.read(workbookServiceProvider);
  return [
    _item(
      label: 'Ligne',
      icon: AppIcons.plus,
      close: close,
      onTap: sheet == null ? null : () => service.addRow(sheet.id),
    ),
    _item(
      label: 'Colonne',
      icon: AppIcons.plus,
      close: close,
      onTap: sheet == null ? null : () => service.addColumn(sheet.id),
    ),
    _item(
      label: 'Feuille',
      icon: AppIcons.plus,
      close: close,
      onTap: () => _newSheet(act),
    ),
  ];
}

// ----------------------------------------------------------------- Format

List<Widget> _format(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
) {
  final column = watch.watch(selectedColumnProvider);
  final cell = watch.watch(selectedCellProvider);
  final selection = watch.watch(selectionProvider);
  final target = column != null && !(selection is CellSelected && cell == null);
  final style = column == null ? null : resolveStyle(column, cell?.row);
  final service = act.read(workbookServiceProvider);
  VoidCallback? apply(CellStyle patch) {
    if (!target) return null;
    return () {
      final row = cell?.row;
      if (row == null) {
        service.styleColumn(column, patch);
      } else {
        service.styleCell(row, column, patch);
      }
    };
  }

  final text = column?.type.hasTextStyle ?? false;
  return [
    _item(
      label: 'Gras',
      checked: style?.bold ?? false,
      close: close,
      onTap: text ? apply(CellStyle(bold: !(style?.bold ?? false))) : null,
    ),
    _item(
      label: 'Italique',
      checked: style?.italic ?? false,
      close: close,
      onTap: text ? apply(CellStyle(italic: !(style?.italic ?? false))) : null,
    ),
    _item(
      label: 'Souligné',
      checked: style?.underline ?? false,
      close: close,
      onTap: text
          ? apply(CellStyle(underline: !(style?.underline ?? false)))
          : null,
    ),
    _divider,
    for (final (align, label, icon) in const [
      (TextAlignment.left, 'Aligner à gauche', AppIcons.alignLeft),
      (TextAlignment.center, 'Centrer', AppIcons.alignCenter),
      (TextAlignment.right, 'Aligner à droite', AppIcons.alignRight),
    ])
      _item(
        label: label,
        icon: icon,
        checked: style?.align == align,
        close: close,
        onTap: apply(CellStyle(align: align)),
      ),
  ];
}

// ---------------------------------------------------------------- Données

List<Widget> _data(
  BuildContext screen,
  WidgetRef watch,
  WidgetRef act,
  VoidCallback close,
) {
  final sheet = watch.watch(activeSheetProvider);
  final column = watch.watch(selectedColumnProvider);
  if (sheet == null) return const [];
  final spec = watch.watch(viewSpecProvider(sheet.id));
  final view = act.read(viewSpecProvider(sheet.id).notifier);
  final sort = spec.query.sort;
  final grouped = column != null && spec.groupBy == column.id;
  return [
    _item(
      label: 'Trier par ordre croissant',
      icon: AppIcons.sortAscending,
      checked: column != null && sort?.columnId == column.id && sort!.ascending,
      close: close,
      onTap: column == null
          ? null
          : () => view.toggleSort(column.id, ascending: true),
    ),
    _item(
      label: 'Trier par ordre décroissant',
      icon: AppIcons.sortDescending,
      checked:
          column != null && sort?.columnId == column.id && !sort!.ascending,
      close: close,
      onTap: column == null
          ? null
          : () => view.toggleSort(column.id, ascending: false),
    ),
    _item(
      label: grouped ? 'Ne plus regrouper' : 'Regrouper par cette colonne',
      icon: AppIcons.group,
      close: close,
      onTap: column == null || !canGroupBy(column.type)
          ? null
          : () => view.setGroupBy(grouped ? null : column.id),
    ),
    _divider,
    _item(
      label: 'Effacer les tris, filtres et regroupement',
      close: close,
      onTap: spec.query.isEmpty && spec.groupBy == null
          ? null
          : view.clearCriteria,
    ),
  ];
}
