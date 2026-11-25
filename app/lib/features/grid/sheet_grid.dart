import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import 'cell_view.dart';
import 'column_header.dart';
import 'grid_providers.dart';

/// La grille d'une feuille : en-têtes de colonnes, numéros de ligne, cellules.
class SheetGrid extends ConsumerWidget {
  const SheetGrid({super.key, required this.sheet});

  final Sheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(columnsProvider(sheet.id)).value;
    final rows = ref.watch(rowsProvider(sheet.id)).value;
    if (columns == null || rows == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selection = ref.watch(selectionProvider);

    final width =
        AppSizes.rowHeaderWidth +
        columns.fold<double>(0, (sum, column) => sum + column.width) +
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
                      active: selection?.columnId == column.id,
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
                  itemExtent: AppSizes.rowHeight,
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
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
                    return Row(
                      key: ValueKey(row.id),
                      children: [
                        _RowNumber(
                          number: row.position + 1,
                          active: selection?.rowId == row.id,
                        ),
                        for (final column in columns)
                          CellView(
                            row: row,
                            column: column,
                            selected:
                                selection?.rowId == row.id &&
                                selection?.columnId == column.id,
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

class _RowNumber extends StatelessWidget {
  const _RowNumber({required this.number, required this.active});

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.rowHeaderWidth,
      height: AppSizes.rowHeight,
      alignment: Alignment.center,
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
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? AppColors.accent : AppColors.textMuted,
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
            child: const Icon(Icons.add, size: 16, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
