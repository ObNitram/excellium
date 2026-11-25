import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import 'cell_format.dart';
import 'column_type_ui.dart';
import 'grid_providers.dart';

/// Une cellule de la grille, rendue selon le type de sa colonne.
class CellView extends ConsumerWidget {
  const CellView({
    super.key,
    required this.row,
    required this.column,
    required this.selected,
  });

  final SheetRow row;
  final ColumnDef column;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = row[column.id];
    return Semantics(
      label: 'Cellule ${column.letter}${row.position + 1}',
      selected: selected,
      child: InkWell(
        onTap: () =>
            ref.read(selectionProvider.notifier).select(row.id, column.id),
        child: Container(
          width: column.width,
          height: AppSizes.rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: selected
                ? Border.all(color: AppColors.accent, width: 2)
                : const Border(
                    right: BorderSide(color: AppColors.gridLine),
                    bottom: BorderSide(color: AppColors.gridLine),
                  ),
          ),
          alignment: column.type.alignsRight
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: _content(ref, value),
        ),
      ),
    );
  }

  Widget _content(WidgetRef ref, CellValue? value) {
    switch (column.type) {
      case ColumnType.boolean:
        final checked = value is BoolValue && value.value;
        return Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: checked,
              activeColor: AppColors.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (next) {
                ref.read(selectionProvider.notifier).select(row.id, column.id);
                ref
                    .read(workbookServiceProvider)
                    .setValue(row, column, BoolValue(next ?? false));
              },
            ),
          ),
        );

      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
        if (value is! CategoryValue) return const SizedBox.shrink();
        return ClipRect(
          child: Row(
            children: [
              for (final category in value.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: _Chip(category),
                ),
            ],
          ),
        );

      case ColumnType.text:
      case ColumnType.number:
      case ColumnType.percent:
      case ColumnType.date:
      case ColumnType.duration:
      case ColumnType.reference:
        return Text(
          formatCell(value, column.type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.text,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),
    );
  }
}
