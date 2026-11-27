import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/pixel_lines.dart';
import '../../shared/confirm.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../columns/column_header.dart';
import '../views/view_providers.dart';
import 'calc_pane.dart';
import 'cell_view.dart';
import 'grid_providers.dart';
import 'group_rows.dart';

/// La grille d'une feuille : en-têtes de colonnes, numéros de ligne, cellules,
/// et sous la table le volet des cases de calcul.
///
/// Elle n'affiche que les colonnes et les lignes retenues par la vue en
/// cours. Si la vue regroupe les lignes, la table alterne en-têtes de groupe,
/// lignes du groupe et pied « Ajouter une ligne ».
class SheetGrid extends ConsumerStatefulWidget {
  const SheetGrid({super.key, required this.sheet});

  final Sheet sheet;

  @override
  ConsumerState<SheetGrid> createState() => _SheetGridState();
}

/// Un élément de la liste verticale de la table.
sealed class _Item {
  const _Item();
}

final class _RowItem extends _Item {
  const _RowItem(this.row);

  final SheetRow row;
}

final class _GroupItem extends _Item {
  const _GroupItem(this.group, {required this.first});

  final RowGroup group;
  final bool first;
}

final class _GroupAddItem extends _Item {
  const _GroupAddItem(this.group);

  final RowGroup group;
}

/// Fin de la table : bouton d'ajout de ligne, ou message.
final class _TailItem extends _Item {
  const _TailItem();
}

class _SheetGridState extends ConsumerState<SheetGrid> {
  // La table et les cases de calcul défilent ensemble à l'horizontale, pour
  // que chaque case reste sous sa colonne.
  final _gridScroll = ScrollController();
  late final ScrollController _calcScroll = ScrollController(
    // Quand le volet réapparaît, il se cale sur la table.
    onAttach: (_) => WidgetsBinding.instance.addPostFrameCallback(
      (_) => _follow(_gridScroll, _calcScroll),
    ),
  );
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _gridScroll.addListener(() => _follow(_gridScroll, _calcScroll));
    _calcScroll.addListener(() => _follow(_calcScroll, _gridScroll));
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    _calcScroll.dispose();
    super.dispose();
  }

  void _follow(ScrollController from, ScrollController to) {
    if (_syncing || !from.hasClients || !to.hasClients) return;
    final offset = from.offset.clamp(0.0, to.position.maxScrollExtent);
    if ((to.offset - offset).abs() < 0.5) return;
    _syncing = true;
    to.jumpTo(offset);
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final allColumns = ref.watch(columnsProvider(sheet.id)).value;
    final allRows = ref.watch(rowsProvider(sheet.id)).value;
    if (allColumns == null || allRows == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final columns = ref.watch(visibleColumnsProvider(sheet.id));
    final rows = ref.watch(visibleRowsProvider(sheet.id));
    final selection = ref.watch(selectionProvider);
    final columnPreview = ref.watch(columnResizeProvider);
    final rowPreview = ref.watch(rowResizeProvider);
    final filtered = ref.watch(
      viewSpecProvider(sheet.id)
          .select((s) => s.query.activeFilters.isNotEmpty),
    );
    final groupColumn = ref.watch(groupColumnProvider(sheet.id));
    final groups = ref.watch(rowGroupsProvider(sheet.id));
    final collapsed = ref.watch(collapsedGroupsProvider);
    final pane = ref.watch(calcPaneProvider);

    double widthOf(ColumnDef column) => columnPreview?.id == column.id.value
        ? columnPreview!.size
        : column.width;
    double heightOf(SheetRow row) => rowPreview?.id == row.id.value
        ? rowPreview!.size
        : (row.height ?? SheetRow.defaultHeight);

    final width =
        AppSizes.rowHeaderWidth +
        columns.fold<double>(0, (sum, column) => sum + widthOf(column)) +
        _AddButton.size;

    final grouped = groupColumn != null && groups != null;
    final items = <_Item>[
      if (grouped)
        for (final (index, group) in groups.indexed) ...[
          _GroupItem(group, first: index == 0),
          if (!collapsed.contains(
            CollapsedGroups.idOf(groupColumn, group),
          )) ...[
            for (final row in group.rows) _RowItem(row),
            if (!group.isNone) _GroupAddItem(group),
          ],
        ]
      else
        for (final row in rows) _RowItem(row),
      const _TailItem(),
    ];

    Widget tail() {
      String? notice;
      if (filtered) {
        notice = rows.isEmpty
            ? 'Aucune ligne ne correspond aux filtres.'
            : 'Des lignes sont masquées par les filtres.';
      } else if (grouped && groups.isEmpty) {
        notice = 'Aucune ligne à regrouper.';
      }
      if (notice != null) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            notice,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        );
      }
      // En vue regroupée, une ligne s'ajoute depuis son groupe : une ligne
      // vide n'appartiendrait à aucun.
      if (grouped) return const SizedBox(height: 12);
      return Align(
        alignment: Alignment.centerLeft,
        child: _AddButton(
          tooltip: 'Ajouter une ligne',
          width: AppSizes.rowHeaderWidth,
          onPressed: () => ref.read(workbookServiceProvider).addRow(sheet.id),
        ),
      );
    }

    Widget buildItem(_Item item) {
      switch (item) {
        case _TailItem():
          return tail();

        case _GroupItem(:final group, :final first):
          return Align(
            alignment: Alignment.centerLeft,
            child: GroupHeader(
              column: groupColumn!,
              group: group,
              columns: columns,
              widthOf: widthOf,
              first: first,
            ),
          );

        case _GroupAddItem(:final group):
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: width - _AddButton.size,
              child: GroupAddRow(
                sheet: sheet,
                column: groupColumn!,
                group: group,
                firstColumn: columns.isEmpty ? null : columns.first,
              ),
            ),
          );

        case _RowItem(:final row):
          final height = heightOf(row);
          return Row(
            children: [
              _RowNumber(
                row: row,
                height: height,
                active: selection is CellSelected && selection.rowId == row.id,
              ),
              for (final column in columns)
                CellView(
                  row: row,
                  column: column,
                  width: widthOf(column),
                  height: height,
                  selected:
                      selection is CellSelected &&
                      selection.rowId == row.id &&
                      selection.columnId == column.id,
                  inSelectedColumn:
                      selection is ColumnSelected &&
                      selection.columnId == column.id,
                ),
            ],
          );
      }
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: _gridScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width < constraints.maxWidth
                    ? constraints.maxWidth
                    : width,
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Corner(),
                        for (final column in columns)
                          ColumnHeader(
                            key: ValueKey(column.id),
                            column: column,
                            width: widthOf(column),
                            allColumns: allColumns,
                          ),
                        _AddButton(
                          tooltip: 'Ajouter une colonne',
                          onPressed: () => ref
                              .read(workbookServiceProvider)
                              .addColumn(sheet.id),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            buildItem(items[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const CalcPaneBar(),
        if (!pane.hidden)
          SizedBox(
            height: pane.height,
            child: CalcGrid(
              sheet: sheet,
              columns: columns,
              widthOf: widthOf,
              contentWidth: width,
              horizontal: _calcScroll,
            ),
          ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner();

  @override
  Widget build(BuildContext context) {
    return const Lined(
      color: AppColors.header,
      edges: [headerEdges],
      child: SizedBox(
        width: AppSizes.rowHeaderWidth,
        height: AppSizes.rowHeight,
      ),
    );
  }
}

/// Numéro d'une ligne, avec une poignée sur son bord bas pour en régler la
/// hauteur (double-clic : hauteur par défaut).
class _RowNumber extends ConsumerStatefulWidget {
  const _RowNumber({
    required this.row,
    required this.height,
    required this.active,
  });

  final SheetRow row;
  final double height;
  final bool active;

  @override
  ConsumerState<_RowNumber> createState() => _RowNumberState();
}

class _RowNumberState extends ConsumerState<_RowNumber> {
  double? _dragHeight;

  /// Supprime la ligne ; une confirmation est demandée si elle a du contenu.
  Future<void> _delete() => deleteRow(context, ref, widget.row);

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final row = widget.row;
    return Lined(
      color: active ? AppColors.accentTint : AppColors.header,
      edges: [
        Edges(
          right: active
              ? const Line(AppColors.accent, 2)
              : const Line(AppColors.headerLine),
          bottom: const Line(AppColors.headerLine),
        ),
      ],
      child: SizedBox(
        width: AppSizes.rowHeaderWidth,
        height: widget.height,
        child: Stack(
          children: [
            // Un clic sur le numéro ouvre le menu de la ligne.
            Positioned.fill(
              child: Popover(
                width: 220,
                anchorBuilder: (context, toggle, isOpen) => Tooltip(
                  message: 'Options de la ligne ${row.position + 1}',
                  waitDuration: const Duration(milliseconds: 600),
                  child: InkWell(
                    onTap: toggle,
                    child: Center(
                      child: Text(
                        '${row.position + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active || isOpen
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: active || isOpen
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                panelBuilder: (context, close) => PanelItem(
                  icon: AppIcons.delete,
                  label: 'Supprimer la ligne ${row.position + 1}',
                  danger: true,
                  onTap: () {
                    close();
                    _delete();
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 6,
              child: Semantics(
                container: true,
                label: 'Régler la hauteur de la ligne ${row.position + 1}',
                child: ResizeGrip(
                  vertical: false,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeRow,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) => _dragHeight = widget.height,
                      onVerticalDragUpdate: (details) {
                        final start = _dragHeight;
                        if (start == null) return;
                        _dragHeight = start + details.delta.dy;
                        ref
                            .read(rowResizeProvider.notifier)
                            .update(
                              row.id.value,
                              _dragHeight!
                                  .clamp(SheetRow.minHeight, SheetRow.maxHeight)
                                  .toDouble(),
                            );
                      },
                      onVerticalDragEnd: (_) async {
                        final height = _dragHeight;
                        _dragHeight = null;
                        if (height != null) {
                          await ref
                              .read(workbookServiceProvider)
                              .resizeRow(row, height);
                        }
                        ref.read(rowResizeProvider.notifier).end();
                      },
                      onDoubleTap: () => ref
                          .read(workbookServiceProvider)
                          .resizeRow(row, null),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.tooltip,
    required this.onPressed,
    this.width = size,
  });

  static const double size = 36;

  final String tooltip;
  final VoidCallback onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: AppSizes.rowHeight,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          child: Semantics(
            button: true,
            label: tooltip,
            child: const Center(
              child: AppIcon(AppIcons.plus, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Supprime [row], après confirmation si elle contient des valeurs.
Future<void> deleteRow(
  BuildContext context,
  WidgetRef ref,
  SheetRow row,
) async {
  final service = ref.read(workbookServiceProvider);
  if (!row.isEmpty) {
    final filled = row.cells.length;
    final confirmed = await confirmDelete(
      context,
      title: 'Supprimer la ligne ${row.position + 1} ?',
      message:
          '${filled > 1 ? 'Ses $filled valeurs seront supprimées' : 'Sa valeur sera supprimée'}'
          '. Ctrl+Z annule la suppression.',
    );
    if (!confirmed) return;
  }
  await service.deleteRow(row);
}
