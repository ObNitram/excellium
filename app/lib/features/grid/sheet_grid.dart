import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/confirm.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../columns/column_header.dart';
import '../views/view_providers.dart';
import 'cell_view.dart';
import 'grid_providers.dart';

/// La grille d'une feuille : en-têtes de colonnes, numéros de ligne, cellules.
/// Elle n'affiche que les colonnes et les lignes retenues par la vue en cours.
class SheetGrid extends ConsumerWidget {
  const SheetGrid({super.key, required this.sheet});

  final Sheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width < constraints.maxWidth ? constraints.maxWidth : width,
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
                    onPressed: () =>
                        ref.read(storeProvider).columns.addColumn(sheet.id),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length + 1,
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      if (filtered) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            rows.isEmpty
                                ? 'Aucune ligne ne correspond aux filtres.'
                                : 'Des lignes sont masquées par les filtres.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      }
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: _AddButton(
                          tooltip: 'Ajouter une ligne',
                          width: AppSizes.rowHeaderWidth,
                          onPressed: () =>
                              ref.read(storeProvider).rows.addRow(sheet.id),
                        ),
                      );
                    }
                    final row = rows[index];
                    final height = heightOf(row);
                    return Row(
                      key: ValueKey(row.id),
                      children: [
                        _RowNumber(
                          row: row,
                          height: height,
                          active:
                              selection is CellSelected &&
                              selection.rowId == row.id,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.rowHeaderWidth,
      height: AppSizes.rowHeight,
      decoration: const BoxDecoration(
        color: AppColors.header,
        border: Border(
          right: BorderSide(color: AppColors.headerLine),
          bottom: BorderSide(color: AppColors.headerLine),
        ),
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
  Future<void> _delete() async {
    final row = widget.row;
    final service = ref.read(workbookServiceProvider);
    if (!row.isEmpty) {
      final filled = row.cells.length;
      final confirmed = await confirmDelete(
        context,
        title: 'Supprimer la ligne ${row.position + 1} ?',
        message:
            '${filled > 1 ? 'Ses $filled valeurs seront perdues' : 'Sa valeur sera perdue'}'
            '. Cette action est définitive.',
      );
      if (!confirmed) return;
    }
    await service.deleteRow(row);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final row = widget.row;
    return Container(
      width: AppSizes.rowHeaderWidth,
      height: widget.height,
      decoration: BoxDecoration(
        color: active ? AppColors.accentTint : AppColors.header,
        border: Border(
          right: BorderSide(
            width: active ? 2 : 1,
            color: active ? AppColors.accent : AppColors.headerLine,
          ),
          bottom: const BorderSide(color: AppColors.headerLine),
        ),
      ),
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
                icon: Icons.delete_outline,
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
            height: 5,
            child: Semantics(
              container: true,
              label: 'Régler la hauteur de la ligne ${row.position + 1}',
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
                  onDoubleTap: () =>
                      ref.read(workbookServiceProvider).resizeRow(row, null),
                ),
              ),
            ),
          ),
        ],
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
            child: const Icon(Icons.add, size: 16, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
